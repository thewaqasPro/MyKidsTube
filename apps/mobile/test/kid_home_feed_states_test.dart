import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_tube/models/category_item.dart';
import 'package:safe_tube/models/child_profile.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/screens/kid_home_screen.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/download_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';
import 'package:safe_tube/widgets/video_card.dart';

class TestFakeDatabaseService extends Fake implements DatabaseService {
  final List<VideoItem> videos;
  final List<CategoryItem> categories;

  TestFakeDatabaseService({
    this.videos = const [],
    this.categories = const [],
  });

  @override
  Future<List<VideoItem>> getAllVideos() async => videos;

  @override
  Future<List<VideoItem>> getDownloadedVideos() async => [];

  @override
  Future<List<CategoryItem>> getAllCategories() async => categories;

  @override
  Future<Set<String>> getFavoriteIds() async => {};

  @override
  Future<String?> getSetting(String key) async => null;

  @override
  Future<void> setSetting(String key, String value) async {}

  @override
  Future<Map<String, dynamic>> getWatchAnalytics({String? profileId}) async => {};

  @override
  Future<Map<String, Map<String, dynamic>>> getVideoWatchSummaries({String? profileId}) async => {};

  @override
  Future<List<ChildProfile>> getAllLocalProfiles() async => [];
}

void main() {
  group('KidHomeScreen Feed State Widget Tests', () {
    testWidgets('renders empty state when no videos are in catalog', (WidgetTester tester) async {
      final fakeDb = TestFakeDatabaseService(videos: [], categories: []);
      final provider = AppProvider(
        db: fakeDb,
        api: FakeVpsApiService(),
        downloader: FakeDownloadService(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: KidHomeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No Videos Found'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('renders populated video feed cards when videos are present', (WidgetTester tester) async {
      final sampleVideos = [
        VideoItem(
          id: 'v_popular_1',
          title: 'Sing Along Rhymes',
          categoryId: 'songs',
          streamUrl: 'https://stream.example/1',
          thumbnailUrl: 'https://thumb.example/1.jpg',
          duration: 180,
          sourceUrl: 'https://youtube.com/watch?v=rhyme1',
        ),
        VideoItem(
          id: 'v_popular_2',
          title: 'Cartoon Adventure Party',
          categoryId: 'cartoons',
          streamUrl: 'https://stream.example/2',
          thumbnailUrl: 'https://thumb.example/2.jpg',
          duration: 240,
          sourceUrl: 'https://youtube.com/watch?v=cart2',
        ),
      ];

      final sampleCategories = [
        CategoryItem(id: 'all', name: 'All Videos'),
        CategoryItem(id: 'songs', name: 'Songs'),
        CategoryItem(id: 'cartoons', name: 'Cartoons'),
      ];

      final fakeDb = TestFakeDatabaseService(
        videos: sampleVideos,
        categories: sampleCategories,
      );
      final provider = AppProvider(
        db: fakeDb,
        api: FakeVpsApiService(),
        downloader: FakeDownloadService(),
      );

      // Trigger catalog sync from DB
      await provider.syncCatalog(autoRetry: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: KidHomeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VideoCard), findsWidgets);
      expect(find.text('Sing Along Rhymes'), findsOneWidget);
      expect(find.text('Cartoon Adventure Party'), findsOneWidget);
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
