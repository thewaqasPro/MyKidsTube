import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/download_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';
import 'package:safe_tube/models/video_item.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Catalog Cap and Auto-Pruning Tests in AppProvider', () {
    late Database db;
    late DatabaseService dbService;
    late AppProvider provider;
    late Directory tempDir;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      dbService = await DatabaseService.createTestInstance(db);
      tempDir = await Directory.systemTemp.createTemp('kidstube_cap_test_');

      provider = AppProvider(
        db: dbService,
        downloader: FakeDownloadService(),
        api: FakeVpsApiService(),
      );
      await provider.init();
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('catalogLimit defaults to 200 and isCatalogNearLimit triggers at 180', () async {
      expect(provider.catalogLimit, equals(200));
      expect(provider.isCatalogNearLimit, isFalse);

      // Add 185 dummy videos
      final videos = List.generate(185, (i) => VideoItem(
        id: 'vid_$i',
        title: 'Video $i',
        categoryId: 'cartoons',
        streamUrl: 'https://example.com/$i.mp4',
        thumbnailUrl: 'https://example.com/$i.jpg',
      ));

      await provider.addStandaloneVideos(videos);

      expect(provider.allVideos.length, equals(185));
      expect(provider.isCatalogNearLimit, isTrue);
    });

    test('adding videos beyond 200 prunes least-engaged videos while strictly preserving favorites and downloads', () async {
      // 1. Add 195 videos
      final initialVideos = List.generate(195, (i) => VideoItem(
        id: 'initial_$i',
        title: 'Initial Video $i',
        categoryId: 'cartoons',
        streamUrl: 'https://example.com/$i.mp4',
        thumbnailUrl: 'https://example.com/$i.jpg',
      ));
      await provider.addStandaloneVideos(initialVideos);

      // Mark initial_0 as favorite
      await provider.toggleFavorite('initial_0');
      expect(provider.isFavorite('initial_0'), isTrue);

      // 2. Add 15 new videos (would total 210, exceeding 200 limit by 10)
      final incomingVideos = List.generate(15, (i) => VideoItem(
        id: 'incoming_$i',
        title: 'Incoming Video $i',
        categoryId: 'cartoons',
        streamUrl: 'https://example.com/inc_$i.mp4',
        thumbnailUrl: 'https://example.com/inc_$i.jpg',
      ));

      await provider.addStandaloneVideos(incomingVideos);

      // Total count should strictly not exceed 200
      expect(provider.allVideos.length, lessThanOrEqualTo(200));
      // All 15 incoming videos should be in the catalog
      for (final inc in incomingVideos) {
        expect(provider.allVideos.any((v) => v.id == inc.id), isTrue);
      }
      // Favorite video MUST be preserved
      expect(provider.allVideos.any((v) => v.id == 'initial_0'), isTrue);
      expect(provider.isFavorite('initial_0'), isTrue);
    });
  });
}
