import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safe_tube/models/category_item.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseService service;
  late Directory tempDir;

  VideoItem createTestVideo(
    String id, {
    String profileId = 'kids_all',
    String? localFilePath,
    String? localThumbPath,
    DownloadStatus status = DownloadStatus.notDownloaded,
  }) {
    return VideoItem(
      id: id,
      title: 'Video $id',
      categoryId: 'cartoons',
      streamUrl: 'https://example.com/$id.mp4',
      thumbnailUrl: 'https://example.com/$id.webp',
      profileId: profileId,
      localFilePath: localFilePath,
      localThumbnailPath: localThumbPath,
      downloadStatus: status,
    );
  }

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    service = await DatabaseService.createTestInstance(db);
    tempDir = await Directory.systemTemp.createTemp('kidstube_test_prune_');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Prompt F10 — Direct Unit Tests of Real pruneRemovedVideos', () {
    test('Empty-sections / empty server list without allowEmpty: false → NO wipe, local videos intact', () async {
      final v1 = createTestVideo('vid_1');
      final v2 = createTestVideo('vid_2');
      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        [v1, v2],
      );

      final before = await service.getAllVideos();
      expect(before.length, equals(2));

      // Server returns empty list (e.g. network glitch or empty sections)
      final pruned = await service.pruneRemovedVideos([], allowEmpty: false);

      expect(pruned, isEmpty, reason: 'Must return empty list without allowEmpty');
      final after = await service.getAllVideos();
      expect(after.length, equals(2), reason: 'All local videos must remain intact in SQLite');
    });

    test('Empty server list WITH explicit allowEmpty: true → permits complete wipe', () async {
      final v1 = createTestVideo('vid_1');
      final v2 = createTestVideo('vid_2');
      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        [v1, v2],
      );

      final pruned = await service.pruneRemovedVideos([], allowEmpty: true, force: true);

      expect(pruned.length, equals(2));
      final after = await service.getAllVideos();
      expect(after, isEmpty, reason: 'All local videos wiped when allowEmpty: true and force: true');
    });

    test('Genuine removals prune unlisted videos while keeping valid server videos', () async {
      final v1 = createTestVideo('vid_1');
      final v2 = createTestVideo('vid_2');
      final v3 = createTestVideo('vid_3');
      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        [v1, v2, v3],
      );

      // Server now only has vid_1 and vid_2 (vid_3 removed)
      final pruned = await service.pruneRemovedVideos(['vid_1', 'vid_2']);

      expect(pruned, equals(['vid_3']));
      final after = await service.getAllVideos();
      expect(after.map((v) => v.id).toList(), containsAll(['vid_1', 'vid_2']));
      expect(after.map((v) => v.id).toList(), isNot(contains('vid_3')));
    });

    test('50%-cap triggers safety guard and blocks deletion unless force: true is provided', () async {
      final videos = List.generate(10, (i) => createTestVideo('vid_$i'));
      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        videos,
      );

      // Attempting to prune 6 of 10 videos (60% > 50%) without force flag
      final pruned = await service.pruneRemovedVideos(
        ['vid_0', 'vid_1', 'vid_2', 'vid_3'],
        force: false,
      );

      expect(pruned, isEmpty, reason: 'Safety cap must block pruning when prune ratio > 50% without force');
      final after = await service.getAllVideos();
      expect(after.length, equals(10), reason: 'All 10 videos preserved');

      // Now with force: true
      final forcedPruned = await service.pruneRemovedVideos(
        ['vid_0', 'vid_1', 'vid_2', 'vid_3'],
        force: true,
      );
      expect(forcedPruned.length, equals(6));
      final afterForced = await service.getAllVideos();
      expect(afterForced.length, equals(4));
    });

    test('Downloaded-file handling per policy: physical video & thumbnail deleted when pruned', () async {
      final videoFile = File('${tempDir.path}/test_video.mp4');
      await videoFile.writeAsString('dummy mp4 content');
      final thumbFile = File('${tempDir.path}/test_thumb.webp');
      await thumbFile.writeAsString('dummy thumbnail content');

      final downloadedVideo = createTestVideo(
        'downloaded_vid_1',
        localFilePath: videoFile.path,
        localThumbPath: thumbFile.path,
        status: DownloadStatus.downloaded,
      );
      final keptVideo = createTestVideo('kept_vid_2');
      final anotherVideo = createTestVideo('kept_vid_3');

      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        [downloadedVideo, keptVideo, anotherVideo],
      );

      // Prune downloadedVideo (1 of 3 = 33% <= 50%)
      final pruned = await service.pruneRemovedVideos(['kept_vid_2', 'kept_vid_3']);

      expect(pruned, equals(['downloaded_vid_1']));

      // Physical files on disk must be deleted!
      expect(await videoFile.exists(), isFalse, reason: 'Local video file must be deleted upon prune');
      expect(await thumbFile.exists(), isFalse, reason: 'Local thumbnail file must be deleted upon prune');

      // Database entry must be removed
      final remaining = await service.getAllVideos();
      expect(remaining.any((v) => v.id == 'downloaded_vid_1'), isFalse);
    });

    test('Per-profile isolation: Pruning Profile A never touches Profile B offline or local videos', () async {
      final aliceVideo = createTestVideo('alice_offline', profileId: 'prof_alice');
      final bobVideo = createTestVideo('bob_offline', profileId: 'prof_bob');
      final sharedVideo = createTestVideo('shared_offline', profileId: 'kids_all');

      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        [aliceVideo, bobVideo, sharedVideo],
      );

      // Pruning for Profile Bob with empty list for Bob
      // Bob's relevant pool is: [bob_offline, shared_offline]
      // Alice's video is NOT in Bob's pool, so Alice's video is NEVER evaluated or pruned!
      final pruned = await service.pruneRemovedVideos(
        ['shared_offline'],
        profileId: 'prof_bob',
      );

      expect(pruned, equals(['bob_offline']));

      final allRemaining = await service.getAllVideos();
      final remainingIds = allRemaining.map((v) => v.id).toList();
      expect(remainingIds, contains('alice_offline'), reason: 'Alice video must NEVER be pruned during Bob sync');
      expect(remainingIds, contains('shared_offline'));
      expect(remainingIds, isNot(contains('bob_offline')));
    });
  });

  group('Tombstone Persistence in Real SQLite Database', () {
    test('deleteVideos permanently records deleted_videos and prevents batchUpsertCatalog resurrection', () async {
      final v1 = createTestVideo('vid_alpha');
      final v2 = createTestVideo('vid_beta');
      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        [v1, v2],
      );

      var list = await service.getAllVideos();
      expect(list.length, equals(2));

      // Delete vid_alpha
      await service.deleteVideos(['vid_alpha']);

      // 1. Must be removed from SQLite videos table
      list = await service.getAllVideos();
      expect(list.length, equals(1));
      expect(list.first.id, equals('vid_beta'));

      // 2. Must be stored in deleted_videos table
      final deletedIds = await service.getDeletedVideoIds();
      expect(deletedIds, contains('vid_alpha'));
      expect(await service.isVideoDeleted('vid_alpha'), isTrue);

      // 3. Re-running batchUpsertCatalog with vid_alpha (e.g. on sync / refresh) must NOT re-insert vid_alpha
      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        [v1, v2],
      );

      list = await service.getAllVideos();
      expect(list.length, equals(1));
      expect(list.first.id, equals('vid_beta'), reason: 'vid_alpha must NOT be resurrected by batchUpsertCatalog');

      // 4. If parent explicitly calls upsertVideo, tombstone is cleared
      await service.upsertVideo(v1);
      list = await service.getAllVideos();
      expect(list.length, equals(2));
      expect(await service.isVideoDeleted('vid_alpha'), isFalse);
    });
  });
}
