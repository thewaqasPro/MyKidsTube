import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/download_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseService dbService;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dbService = await DatabaseService.createTestInstance(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Starter Catalog Unit Tests', () {
    test('bundled starter_catalog.json contains valid 60 videos and 6 categories', () {
      final file = File('assets/starter_catalog.json');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final data = json.decode(content) as Map<String, dynamic>;

      expect(data['categories'], isList);
      final categories = data['categories'] as List;
      expect(categories.length, equals(6));

      expect(data['videos'], isList);
      final videos = data['videos'] as List;
      expect(videos.length, equals(60));

      final shorts = videos.where((v) => v['category_id'] == 'shorts').toList();
      final longVideos = videos.where((v) => v['category_id'] != 'shorts').toList();

      expect(shorts.length, equals(30));
      expect(longVideos.length, equals(30));

      // Check all have youtube_id and status embed
      for (final v in videos) {
        expect(v['youtube_id'], isNotNull);
        expect((v['youtube_id'] as String).isNotEmpty, isTrue);
        expect(v['status'], equals('embed'));
        expect(v['thumbnail_url'], startsWith('https://i.ytimg.com/vi/'));
      }
    });

    test('loadStarterCatalog populates in-memory database and marks flags', () async {
      final file = File('assets/starter_catalog.json');
      final rawJson = file.readAsStringSync();

      final provider = AppProvider(
        db: dbService,
        api: FakeVpsApiService(),
        downloader: FakeDownloadService(),
      );

      expect(await provider.isStarterPackPrompted(), isFalse);
      expect(await provider.isStarterPackLoaded(), isFalse);

      final count = await provider.loadStarterCatalog(rawJsonOverride: rawJson);
      expect(count, equals(60));

      expect(await provider.isStarterPackPrompted(), isTrue);
      expect(await provider.isStarterPackLoaded(), isTrue);

      final loadedVideos = await dbService.getAllVideos();
      expect(loadedVideos.length, equals(60));

      final loadedCategories = await dbService.getAllCategories();
      expect(loadedCategories.length, equals(6));

      // Verify category distribution
      final shortsInDb = loadedVideos.where((v) => v.isShort).toList();
      expect(shortsInDb.length, equals(30));

      final longInDb = loadedVideos.where((v) => !v.isShort).toList();
      expect(longInDb.length, equals(30));
    });

    test('loadStarterCatalog respects resetTombstones true vs false', () async {
      final file = File('assets/starter_catalog.json');
      final rawJson = file.readAsStringSync();

      final provider = AppProvider(
        db: dbService,
        api: FakeVpsApiService(),
        downloader: FakeDownloadService(),
      );

      // Load initially
      await provider.loadStarterCatalog(rawJsonOverride: rawJson);
      expect((await dbService.getAllVideos()).length, equals(60));

      // Delete two videos
      final toDelete = ['XqZsoesa55w', 'e_04ZrNroTo'];
      await dbService.deleteVideos(toDelete);

      // Deletion is tombstoned
      final afterDelete = await dbService.getAllVideos();
      expect(afterDelete.length, equals(58));
      expect(await dbService.isVideoDeleted('XqZsoesa55w'), isTrue);

      // Reloading with resetTombstones = false should NOT resurrect them
      await provider.loadStarterCatalog(resetTombstones: false, rawJsonOverride: rawJson);
      final afterFalseReload = await dbService.getAllVideos();
      expect(afterFalseReload.length, equals(58));

      // Reloading with resetTombstones = true unmarks deleted and restores all 60
      await provider.loadStarterCatalog(resetTombstones: true, rawJsonOverride: rawJson);
      final afterTrueReload = await dbService.getAllVideos();
      expect(afterTrueReload.length, equals(60));
      expect(await dbService.isVideoDeleted('XqZsoesa55w'), isFalse);
    });

    test('markStarterPackPrompted records setting without loading catalog', () async {
      final provider = AppProvider(
        db: dbService,
        api: FakeVpsApiService(),
        downloader: FakeDownloadService(),
      );

      expect(await provider.isStarterPackPrompted(), isFalse);
      await provider.markStarterPackPrompted();
      expect(await provider.isStarterPackPrompted(), isTrue);
      expect(await provider.isStarterPackLoaded(), isFalse);
      expect((await dbService.getAllVideos()).isEmpty, isTrue);
    });
  });
}

class FakeVpsApiService extends Fake implements VpsApiService {
  @override
  Future<bool> checkHealth(String baseUrl) async => true;

  @override
  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl, {String? profileId}) async => null;
}

class FakeDownloadService extends Fake implements DownloadService {
  @override
  Future<int> getTotalCachedBytes() async => 0;
}
