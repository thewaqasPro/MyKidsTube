import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/models/category_item.dart';
import 'package:safe_tube/models/child_profile.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/screens/kid_player_screen.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/download_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async => 1;

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return Stream.value(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 120),
      size: const Size(1920, 1080),
    ));
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> play(int textureId) async {}

  @override
  Future<void> pause(int textureId) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Future<Duration> getPosition(int textureId) async => Duration.zero;

  @override
  Future<void> dispose(int textureId) async {}

  @override
  Widget buildView(int textureId) => const SizedBox();
}

class TestWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return TestWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return TestWebViewWidget(params);
  }
}

class TestWebViewController extends PlatformWebViewController {
  TestWebViewController(super.params) : super.implementation();

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}
  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}
}

class TestWebViewWidget extends PlatformWebViewWidget {
  TestWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox(key: Key('test_webview'));
}

class TestFakeDatabaseService extends Fake implements DatabaseService {
  final Map<String, String> _settings = {};

  @override
  Future<List<VideoItem>> getAllVideos({String? profileId}) async => [];
  @override
  Future<List<VideoItem>> getDownloadedVideos({String? profileId}) async => [];
  @override
  Future<List<CategoryItem>> getAllCategories() async => [];
  @override
  Future<Set<String>> getFavoriteIds({String? profileId}) async => {};
  @override
  Future<String?> getSetting(String key) async => _settings[key];
  @override
  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }
  @override
  Future<Map<String, dynamic>> getWatchAnalytics({String? profileId}) async => {};
  @override
  Future<Map<String, Map<String, dynamic>>> getVideoWatchSummaries({String? profileId}) async => {};
  @override
  Future<List<ChildProfile>> getAllLocalProfiles() async => [];
  @override
  Future<void> recordWatchSession({
    required String videoId,
    String? videoTitle,
    String? categoryId,
    required int secondsWatched,
    int videoDuration = 0,
    bool isCompleted = false,
    bool isSkipped = false,
    String? profileId,
    String? profileName,
    String? deviceId,
  }) async {}
  @override
  Future<bool> getAutoplayEnabled() async => true;
  @override
  Future<int> getAutoplaySessionLimitMinutes() async => 60;
}

class FakeVpsApiService extends Fake implements VpsApiService {
  @override
  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl, {String? profileId}) async => null;
  @override
  Future<bool> checkHealth(String baseUrl) async => true;
}

class FakeDownloadService extends Fake implements DownloadService {
  @override
  Future<int> getTotalCachedBytes() async => 0;
}

VideoItem createTestVideo({String id = 'vid1'}) {
  return VideoItem(
    id: id,
    title: 'Colors Song • Nursery Rhymes',
    categoryId: 'learning',
    sourceUrl: 'https://youtube.com/watch?v=abc123xyz00',
    duration: 120,
    streamUrl: 'https://example.com/test_video.mp4',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    status: 'ready',
    youtubeId: 'abc123xyz00',
  );
}

Widget buildTestApp({
  required AppProvider provider,
  required VideoItem video,
  Size screenSize = const Size(500, 900),
}) {
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: screenSize,
          padding: EdgeInsets.zero,
        ),
        child: KidPlayerScreen(
          video: video,
          playlist: [video],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    WebViewPlatform.instance = TestWebViewPlatform();
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async => null,
    );
  });

  group('Long-form Video Player Orientation Button Tests', () {
    testWidgets('Orientation toggle button is rendered on KidPlayerScreen in portrait mode', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.portrait);

      final video = createTestVideo();
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(500, 900)));
      await tester.pump();

      // Right action column orientation button (landscape target icon in portrait)
      expect(find.byIcon(Icons.stay_current_landscape_rounded), findsOneWidget);

      // Bottom controls fullscreen / orientation toggle button
      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
    });

    testWidgets('Orientation toggle button rotates to landscape on tap', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.portrait);

      final video = createTestVideo();
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(500, 900)));
      await tester.pump();

      expect(provider.orientationMode, AppOrientationMode.portrait);

      // Tap orientation button in floating action column
      final orientationActionBtn = find.byIcon(Icons.stay_current_landscape_rounded);
      expect(orientationActionBtn, findsOneWidget);
      await tester.tap(orientationActionBtn);
      await tester.pumpAndSettle();

      // Provider orientation mode switched to landscape
      expect(provider.orientationMode, AppOrientationMode.landscape);
    });

    testWidgets('Shorts screen (KidShortsFeedScreen) does NOT have orientation buttons', (tester) async {
      final shortsContent = File('lib/screens/kid_shorts_feed_screen.dart').readAsStringSync();
      expect(shortsContent.contains('stay_current_landscape_rounded'), isFalse);
      expect(shortsContent.contains('fullscreen_rounded'), isFalse);
      expect(shortsContent.contains('OrientationModeSwitch'), isFalse);
    });
  });
}
