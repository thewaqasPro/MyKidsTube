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

      expect(pruned.toSet(), equals({'vid_1', 'vid_2'}));
      final after = await service.getAllVideos();
      expect(after, isEmpty);
    });

    test('Genuine removals prune unlisted videos while keeping valid server videos', () async {
      final v1 = createTestVideo('vid_keep_1');
      final v2 = createTestVideo('vid_delete_2');
      final v3 = createTestVideo('vid_keep_3');
      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        [v1, v2, v3],
      );

      // Server now only contains v1 and v3 (1 of 3 deleted = 33% <= 50% cap)
      final pruned = await service.pruneRemovedVideos(['vid_keep_1', 'vid_keep_3']);

      expect(pruned, equals(['vid_delete_2']));

      final remaining = await service.getAllVideos();
      expect(remaining.map((v) => v.id).toList(), unorderedEquals(['vid_keep_1', 'vid_keep_3']));
    });

    test('50%-cap triggers safety guard and blocks deletion unless force: true is provided', () async {
      // Seed 10 videos
      final videos = List.generate(10, (i) => createTestVideo('v_${i + 1}'));
      await service.batchUpsertCatalog(
        [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        videos,
      );

      // Server only contains 4 videos: 6 to delete = 60% > 50% maxPruneRatio
      final validIds = ['v_1', 'v_2', 'v_3', 'v_4'];

      // 1. Without force -> blocked by safety cap
      final blockedPrune = await service.pruneRemovedVideos(validIds, force: false);
      expect(blockedPrune, isEmpty, reason: 'Safety cap must block bulk wipe without force confirmation');

      final localAfterBlock = await service.getAllVideos();
      expect(localAfterBlock.length, equals(10), reason: 'All 10 videos must remain intact');

      // 2. With explicit force: true -> successfully prunes
      final forcedPrune = await service.pruneRemovedVideos(validIds, force: true);
      expect(forcedPrune.length, equals(6));
      expect(forcedPrune, unorderedEquals(['v_5', 'v_6', 'v_7', 'v_8', 'v_9', 'v_10']));

      final localAfterForce = await service.getAllVideos();
      expect(localAfterForce.length, equals(4));
    });

    test('Downloaded-file handling per policy: physical video & thumbnail deleted when pruned', () async {
      final videoFile = File('${tempDir.path}/sample_video.mp4');
      await videoFile.writeAsString('dummy mp4 content');
      final thumbFile = File('${tempDir.path}/sample_thumb.webp');
      await thumbFile.writeAsString('dummy webp content');

      expect(await videoFile.exists(), isTrue);
      expect(await thumbFile.exists(), isTrue);

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
}
