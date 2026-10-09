import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/models/category_item.dart';
import 'package:safe_tube/models/child_profile.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/screens/parent_dashboard_screen.dart';
import 'package:safe_tube/screens/parent_security_screen.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/download_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';
import 'package:safe_tube/widgets/kid_embed_player.dart';

class FakeVpsApiService extends Fake implements VpsApiService {
  @override
  void setAuthToken(String? token) {}

  @override
  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl, {String? profileId}) async => null;

  @override
  Future<bool> checkHealth(String baseUrl) async => true;
}

class CorruptThrowingDatabaseService extends Fake implements DatabaseService {
  bool recovered = false;

  @override
  Future<List<CategoryItem>> getAllCategories() async {
    if (!recovered) {
      throw const FileSystemException('database disk image is malformed');
    }
    return [];
  }

  @override
  Future<List<VideoItem>> getAllVideos() async => [];

  @override
  Future<List<VideoItem>> getDownloadedVideos() async => [];

  @override
  Future<Set<String>> getFavoriteIds() async => {};

  @override
  Future<List<ChildProfile>> getAllLocalProfiles() async => [];

  @override
  Future<Map<String, dynamic>> getWatchAnalytics({String? profileId}) async => {'today_seconds': 0};

  @override
  Future<String?> getSetting(String key) async => null;

  @override
  Future<void> setSetting(String key, String value) async {}

  @override
  Future<void> recoverCorruptedDatabase() async {
    recovered = true;
  }
}

void main() {
  group('R8 — Player Honesty & Sandbox Shield Tests', () {
    test('KidEmbedPlayer defaults to scale 1.0 and zoom 1.0', () {
      const player = KidEmbedPlayer(youtubeId: 'abc12345678');
      expect(player.scale, equals(1.0));
      expect(player.zoom, equals(1.0));
    });

    test('KidEmbedPlayer embed source and postMessage strings contain controls=0 and scoped origin', () {
      final file = File('lib/widgets/kid_embed_player.dart');
      final content = file.readAsStringSync();

      // Check controls=0 in URL
      expect(content.contains('controls=0'), isTrue,
          reason: 'Embed URL must include controls=0');

      // Check origin scoping in postMessage
      expect(content.contains("postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":\"\"}', 'https://www.youtube-nocookie.com')"), isTrue,
          reason: 'postMessage must be scoped to https://www.youtube-nocookie.com instead of wildcard *');

      // Ensure no wildcard postMessage exists in the player
      expect(content.contains("postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":\"\"}', '*')"), isFalse,
          reason: 'Wildcard * postMessage must not be used');
    });

    test('Call sites in kid_player_screen and kid_shorts_feed_screen pass scale: 1.14', () {
      final playerScreen = File('lib/screens/kid_player_screen.dart').readAsStringSync();
      final shortsScreen = File('lib/screens/kid_shorts_feed_screen.dart').readAsStringSync();

      expect(playerScreen.contains('scale: 1.14'), isTrue,
          reason: 'kid_player_screen.dart must specify scale: 1.14');
      expect(shortsScreen.contains('scale: 1.14'), isTrue,
          reason: 'kid_shorts_feed_screen.dart must specify scale: 1.14');
    });
  });

  group('R8 — PIN Enforcement & Parent Area Gating Tests', () {
    testWidgets('ParentDashboardScreen displays Locked UI when default PIN is active', (tester) async {
      final provider = AppProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ParentDashboardScreen(isUsingDefaultPinOverride: true),
          ),
        ),
      );

      // Verify dashboard is locked
      expect(find.text('Parent Dashboard Locked'), findsOneWidget);
      expect(find.text('Set New PIN to Unlock'), findsOneWidget);
      expect(find.text('For child safety, the default PIN (1234) must be changed before accessing parental controls and dashboard settings.'), findsOneWidget);

      // Verify management sections are hidden / not accessible
      expect(find.text('Media Library'), findsNothing);
      expect(find.text('Watch Time & Analytics'), findsNothing);
      expect(find.text('Device Storage & Media'), findsNothing);
    });

    testWidgets('ParentDashboardScreen displays full controls when PIN is changed', (tester) async {
      final provider = AppProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ParentDashboardScreen(isUsingDefaultPinOverride: false),
          ),
        ),
      );

      // Verify normal dashboard elements are reachable
      expect(find.text('Parent Dashboard Locked'), findsNothing);
      expect(find.text('Media Library'), findsOneWidget);
      expect(find.text('Watch Time & Analytics'), findsOneWidget);
      expect(find.text('Device Storage & Media'), findsOneWidget);
      expect(find.text('PIN & Security Settings'), findsOneWidget);
      expect(find.text('VPS Server Connection'), findsOneWidget);
    });

    testWidgets('ParentSecurityScreen renders Mandatory PIN Setup banner when isForceChange is true', (tester) async {
      final provider = AppProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ParentSecurityScreen(isForceChange: true),
          ),
        ),
      );

      expect(find.text('Mandatory PIN Setup'), findsOneWidget);
      expect(find.text('The default PIN (1234) must be replaced before accessing parental controls.'), findsOneWidget);
    });
  });

  group('R8 — Storage Pre-Flight Check Tests', () {
    tearDown(() {
      DownloadService.freeDiskSpaceOverride = null;
    });

    test('formatBytes formats KB, MB, and GB accurately', () {
      expect(DownloadService.formatBytes(500 * 1024), equals('500.0 KB'));
      expect(DownloadService.formatBytes(50 * 1024 * 1024), equals('50.0 MB'));
      expect(DownloadService.formatBytes(2 * 1024 * 1024 * 1024), equals('2.00 GB'));
    });

    test('downloadVideo aborts pre-flight when free disk space is insufficient with explicit shortfall', () async {
      // Simulate only 10 MB available disk space
      DownloadService.freeDiskSpaceOverride = (path) => 10 * 1024 * 1024;

      final video = VideoItem(
        id: 'test_vid_1',
        title: 'Bedtime Stories',
        channelName: 'Kids Storybook',
        categoryId: 'stories',
        thumbnailUrl: 'https://example.com/thumb1.jpg',
        fileSizeBytes: 50 * 1024 * 1024, // Requires 50 MB
        streamUrl: 'https://example.com/stream.mp4',
      );

      final success = await DownloadService.instance.downloadVideo(video);

      expect(success, isFalse);
      expect(DownloadService.instance.isDownloading(video.id), isFalse);
      expect(DownloadService.instance.lastErrorMessage, contains('Not enough storage space for \'Bedtime Stories\''));
      expect(DownloadService.instance.lastErrorMessage, contains('Short by 40.0 MB'));
    });

    test('AppProvider.startDownload returns explicit shortfall message on insufficient storage', () async {
      // Simulate 5 MB available
      DownloadService.freeDiskSpaceOverride = (path) => 5 * 1024 * 1024;

      final provider = AppProvider();
      final video = VideoItem(
        id: 'test_vid_2',
        title: 'Nursery Rhymes',
        channelName: 'Rhyme Time',
        categoryId: 'music',
        thumbnailUrl: 'https://example.com/thumb2.jpg',
        fileSizeBytes: 20 * 1024 * 1024, // Needs 20 MB
        streamUrl: 'https://example.com/rhyme.mp4',
      );

      final error = await provider.startDownload(video);

      expect(error, isNotNull);
      expect(error, contains('Not enough storage space for \'Nursery Rhymes\''));
      expect(error, contains('Short by 15.0 MB'));
      expect(provider.lastStorageError, equals(error));
    });
  });

  group('R8 — Corrupt DB File Recovery Tests', () {
    test('AppProvider recovers from corrupt DB file during init and load without throwing', () async {
      final fakeDb = CorruptThrowingDatabaseService();
      final provider = AppProvider(
        db: fakeDb,
        api: FakeVpsApiService(),
        downloader: DownloadService.instance,
      );

      // Should complete without throwing DatabaseException or crashing into black screen
      await provider.init();

      expect(fakeDb.recovered, isTrue,
          reason: 'Corrupted database must trigger recoverCorruptedDatabase()');
      expect(provider.isLoading, isFalse,
          reason: 'isLoading must be false to avoid permanent splash/black screen');
      expect(provider.allVideos, isEmpty);
      expect(provider.categories, isEmpty);
    });
  });
}
