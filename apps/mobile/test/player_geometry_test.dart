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
import 'package:safe_tube/widgets/kid_embed_player.dart';
import 'package:safe_tube/widgets/player_control_drawer.dart';
import 'package:safe_tube/widgets/player_suggestion_drawer.dart';
import 'package:safe_tube/widgets/touch_lock_overlay.dart';

// ---------------------------------------------------------------------------
// Test Platform Mocks
// ---------------------------------------------------------------------------

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
  Widget buildView(int textureId) {
    return const SizedBox(key: ValueKey('fake_video_player_view'));
  }
}

class TestWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return TestPlatformWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return TestPlatformWebViewWidget(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return TestPlatformNavigationDelegate(params);
  }
}

class TestPlatformNavigationDelegate extends PlatformNavigationDelegate {
  TestPlatformNavigationDelegate(super.params) : super.implementation();
  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback onNavigationRequest) async {}
  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}
  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback onWebResourceError) async {}
}

class TestPlatformWebViewController extends PlatformWebViewController {
  TestPlatformWebViewController(super.params) : super.implementation();
  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}
  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams javaScriptChannelParams) async {}
}

class TestPlatformWebViewWidget extends PlatformWebViewWidget {
  TestPlatformWebViewWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox(key: ValueKey('test_webview'));
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

VideoItem createTestVideo({bool needsEmbed = false, String id = 'test_vid_1'}) {
  return VideoItem(
    id: id,
    title: 'Colors Song • Nursery Rhymes',
    categoryId: 'learning',
    streamUrl: 'https://example.com/test_video.mp4',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    status: needsEmbed ? 'pending_download' : 'ready',
    youtubeId: 'abc123xyz00',
  );
}

Widget buildTestApp({
  required AppProvider provider,
  required VideoItem video,
  List<VideoItem> playlist = const [],
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
          playlist: playlist,
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

  group('Full-Screen Infinite Swipe Player Geometry Tests', () {
    testWidgets('Portrait mode geometry: player surface occupies 100% full screen with vertical PageView', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.auto);

      final video = createTestVideo(needsEmbed: true);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(500, 900)));
      await tester.pump();

      // PageView is present with vertical scrolling
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);
      final pageView = tester.widget<PageView>(pageViewFinder);
      expect(pageView.scrollDirection, equals(Axis.vertical));

      // Video surface fills 100% of the screen
      final embedFinder = find.byType(KidEmbedPlayer);
      expect(embedFinder, findsOneWidget);
      final playerRect = tester.getRect(embedFinder);
      expect(playerRect.left, equals(0.0));
      expect(playerRect.top, equals(0.0));
      expect(playerRect.width, equals(500.0));
      expect(playerRect.height, equals(900.0));
    });

    testWidgets('Landscape mode geometry: full-screen video with zero permanent sidebars or top bars', (tester) async {
      tester.view.physicalSize = const Size(900, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.landscape);

      final video = createTestVideo(needsEmbed: true);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(900, 500)));
      await tester.pump();

      // Player surface fills full screen (900x500)
      final embedFinder = find.byType(KidEmbedPlayer);
      expect(embedFinder, findsOneWidget);
      final playerRect = tester.getRect(embedFinder);
      expect(playerRect.left, equals(0.0));
      expect(playerRect.top, equals(0.0));
      expect(playerRect.width, equals(900.0));
      expect(playerRect.height, equals(500.0));
    });

    testWidgets('Horizontal drag gestures open Left Control Drawer and Right Suggestion Drawer', (tester) async {
      tester.view.physicalSize = const Size(900, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());

      final video = createTestVideo(needsEmbed: true);
      final playlist = [video, createTestVideo(id: 'vid2'), createTestVideo(id: 'vid3')];
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, playlist: playlist, screenSize: const Size(900, 500)));
      await tester.pump();

      // Drawers are initially mounted as overlays
      expect(find.byType(PlayerControlDrawer), findsOneWidget);
      expect(find.byType(PlayerSuggestionDrawer), findsOneWidget);

      final controlDrawer = tester.widget<PlayerControlDrawer>(find.byType(PlayerControlDrawer));
      expect(controlDrawer.isOpen, isFalse);

      final suggestionDrawer = tester.widget<PlayerSuggestionDrawer>(find.byType(PlayerSuggestionDrawer));
      expect(suggestionDrawer.isOpen, isFalse);

      // Swipe right from center to open Left Control Drawer
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pump();

      final openControlDrawer = tester.widget<PlayerControlDrawer>(find.byType(PlayerControlDrawer));
      expect(openControlDrawer.isOpen, isTrue);

      // Close it via tap on dismiss barrier
      openControlDrawer.onClose();
      await tester.pump();

      final closedControlDrawer = tester.widget<PlayerControlDrawer>(find.byType(PlayerControlDrawer));
      expect(closedControlDrawer.isOpen, isFalse);

      // Swipe left from center to open Right Suggestion Drawer
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump();

      final openSuggestionDrawer = tester.widget<PlayerSuggestionDrawer>(find.byType(PlayerSuggestionDrawer));
      expect(openSuggestionDrawer.isOpen, isTrue);
    });
  });

  group('Toddler Lock and Layer Overlay Tests', () {
    testWidgets('TouchLockOverlay is positioned above player surface and disables gestures when locked', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());

      final video = createTestVideo(needsEmbed: false);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(500, 900)));
      await tester.pump();

      expect(find.byType(TouchLockOverlay), findsOneWidget);

      // Lock screen
      final touchLock = tester.widget<TouchLockOverlay>(find.byType(TouchLockOverlay));
      touchLock.onLock();
      await tester.pump();

      // When locked, PageView scroll physics are disabled
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.physics, isA<NeverScrollableScrollPhysics>());
    });
  });

  group('Shield Region Coverage & Opaque Touch Blocking Tests', () {
    testWidgets('KidEmbedPlayer: Top and bottom shields cover full chrome bounds with opaque gesture detectors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 280,
              child: KidEmbedPlayer(
                youtubeId: 'test_shield_123',
                autoPlay: true,
                scale: 1.14,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final topShieldPositioned = tester.widgetList<Positioned>(
        find.descendant(of: find.byType(KidEmbedPlayer), matching: find.byType(Positioned)),
      ).firstWhere((p) => p.top == 0.0 && p.left == 0.0 && p.right == 0.0 && p.bottom == null);

      expect(topShieldPositioned.top, equals(0.0));
      expect(topShieldPositioned.left, equals(0.0));
      expect(topShieldPositioned.right, equals(0.0));
      expect(topShieldPositioned.height, greaterThanOrEqualTo(50.0));

      final bottomShieldPositioned = tester.widgetList<Positioned>(
        find.descendant(of: find.byType(KidEmbedPlayer), matching: find.byType(Positioned)),
      ).firstWhere((p) => p.bottom == 0.0 && p.left == 0.0 && p.right == 0.0 && p.top == null);

      expect(bottomShieldPositioned.bottom, equals(0.0));
      expect(bottomShieldPositioned.left, equals(0.0));
      expect(bottomShieldPositioned.right, equals(0.0));
      expect(bottomShieldPositioned.height, greaterThanOrEqualTo(50.0));

      final gestureDetectors = tester.widgetList<GestureDetector>(
        find.descendant(of: find.byType(KidEmbedPlayer), matching: find.byType(GestureDetector)),
      ).toList();

      expect(gestureDetectors.length, greaterThanOrEqualTo(2));
      for (final gd in gestureDetectors) {
        expect(gd.behavior, equals(HitTestBehavior.opaque));
      }
    });
  });
}
