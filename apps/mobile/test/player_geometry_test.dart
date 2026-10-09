import 'dart:ui';
import 'package:flutter/material.dart';
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
import 'package:safe_tube/widgets/orientation_mode_switch.dart';
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
  Future<void> recordWatchEvent({
    required String videoId,
    required String videoTitle,
    required String categoryId,
    required int secondsWatched,
    required int videoDuration,
    required bool isCompleted,
    required bool isSkipped,
    String? profileId,
  }) async {}

  @override
  Future<bool> getAutoplayEnabled() async => true;

  @override
  Future<int> getAutoplaySessionLimitMinutes() async => 60;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

VideoItem createTestVideo({bool needsEmbed = false}) {
  return VideoItem(
    id: 'test_vid_1',
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
  Size screenSize = const Size(400, 800),
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

  group('Prompt F12 — Player Geometry & Dynamic Positioning Tests', () {
    testWidgets('Portrait mode geometry: player surface occupies natural 16:9 below 40px top bar', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.auto);

      final video = createTestVideo(needsEmbed: true);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(400, 800)));
      await tester.pump();

      // Top bar is present at top: 0, height: 40
      final topBarFinder = find.byType(OrientationModeSwitch);
      expect(topBarFinder, findsOneWidget);

      // Player surface geometry in portrait
      // availableWidth = 400, 16:9 ratio => height = 400 / (16/9) = 225
      final embedFinder = find.byType(KidEmbedPlayer);
      expect(embedFinder, findsOneWidget);

      final playerRect = tester.getRect(embedFinder);
      expect(playerRect.left, equals(0.0));
      expect(playerRect.top, equals(40.0), reason: 'Player must start immediately below 40px top bar');
      expect(playerRect.width, equals(400.0), reason: 'Player width must fill screen width in portrait');
      expect(playerRect.height, closeTo(225.0, 0.5), reason: 'Player height must maintain 16:9 aspect ratio');
    });

    testWidgets('Landscape Split mode geometry: player occupies left clamped region below 40px top bar', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.landscape);

      final video = createTestVideo(needsEmbed: true);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(800, 400)));
      await tester.pump();

      // Top bar remains visible in split landscape
      expect(find.byType(OrientationModeSwitch), findsOneWidget);

      // Landscape split geometry:
      // availableHeight = (400 - 40) = 360
      // naturalWidth = 360 * 16/9 = 640
      // maxVideoWidth = clamp(200, 800 * 0.76 = 608) = 608
      // playerWidth = 640.clamp(200, 608) = 608
      final embedFinder = find.byType(KidEmbedPlayer);
      expect(embedFinder, findsOneWidget);

      final playerRect = tester.getRect(embedFinder);
      expect(playerRect.left, equals(0.0));
      expect(playerRect.top, equals(40.0), reason: 'Player starts below 40px top bar in split landscape');
      expect(playerRect.width, closeTo(608.0, 0.5), reason: 'Player width clamped to 76% available width');
      expect(playerRect.height, equals(360.0), reason: 'Player height occupies remaining screen height below top bar');
    });

    testWidgets('Immersive Fullscreen mode geometry: player fills 100% of screen (0, 0, width, height)', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.landscape);

      final video = createTestVideo(needsEmbed: true);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(800, 400)));
      await tester.pump();

      // Enter fullscreen via top-bar fullscreen button
      final fullscreenBtn = find.byTooltip('Full Bleed Video');
      expect(fullscreenBtn, findsOneWidget);
      await tester.tap(fullscreenBtn);
      await tester.pump();

      // In immersive fullscreen, player fills full screen
      final embedFinder = find.byType(KidEmbedPlayer);
      final playerRect = tester.getRect(embedFinder);
      expect(playerRect.left, equals(0.0));
      expect(playerRect.top, equals(0.0), reason: 'Player must start at (0,0) in immersive fullscreen');
      expect(playerRect.width, equals(800.0), reason: 'Player must fill full width in immersive fullscreen');
      expect(playerRect.height, equals(400.0), reason: 'Player must fill full height in immersive fullscreen');

      // Top bar is removed in immersive fullscreen
      expect(find.byType(OrientationModeSwitch), findsNothing);

      // Floating exit button appears
      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);
    });
  });

  group('Prompt F12 — Layer Stack Order & Overlay Hierarchy Tests', () {
    testWidgets('Layer stack order: Player Surface -> Top Bar -> Playlist -> Exit Button -> Touch Lock Overlay', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());

      final video = createTestVideo(needsEmbed: false);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(400, 800)));
      await tester.pump();

      // Locate the main body Stack under Scaffold
      final scaffoldStackFinder = find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(Stack),
      );
      final Stack rootStack = tester.widget<Stack>(scaffoldStackFinder.first);

      // Verify layer stack children types & ordering:
      // Index 0: Positioned (Player Surface)
      // Index 1: Positioned (MP4 Scrubber & Controls)
      // Index 2: Positioned (Fixed Top Bar)
      // Index 3: Positioned (Portrait Details & Playlist)
      // Index 4: TouchLockOverlay
      expect(rootStack.children.length, greaterThanOrEqualTo(4));

      final firstChild = rootStack.children[0];
      expect(firstChild, isA<Positioned>(), reason: 'Layer 1 must be Positioned player surface');

      // TouchLockOverlay must be positioned above player surface, controls, top bar and playlist
      final touchLockIndex = rootStack.children.indexWhere((c) => c is TouchLockOverlay);
      expect(touchLockIndex, greaterThan(0), reason: 'TouchLockOverlay must be higher in Z-order than player surface');

      // Ensure TouchLockOverlay widget is present in tree
      expect(find.byType(TouchLockOverlay), findsOneWidget);
    });
  });

  group('Prompt F12 — Top Bar Presence & Absence Rules', () {
    testWidgets('Top bar present in normal portrait & landscape split, absent when locked or immersive', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());

      final video = createTestVideo(needsEmbed: true);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(400, 800)));
      await tester.pump();

      // 1. Portrait: Top bar present
      expect(find.byType(OrientationModeSwitch), findsOneWidget);
      expect(find.byTooltip('Lock Screen'), findsOneWidget);

      // 2. Lock screen: Top bar absent
      await tester.tap(find.byTooltip('Lock Screen'));
      await tester.pump();
      expect(find.byType(OrientationModeSwitch), findsNothing, reason: 'Top bar must be absent when locked');
      expect(find.byTooltip('Lock Screen'), findsNothing);

      // Unlock
      final unlockBtn = find.text('Hold to Unlock');
      expect(unlockBtn, findsOneWidget);
      await tester.longPress(unlockBtn);
      await tester.pump();
      expect(find.byType(OrientationModeSwitch), findsOneWidget, reason: 'Top bar restored after unlocking');

      // 3. Immersive fullscreen: Top bar absent
      final fsBtn = find.byTooltip('Landscape Fullscreen');
      expect(fsBtn, findsOneWidget);
      await tester.tap(fsBtn);
      await tester.pump();
      expect(find.byType(OrientationModeSwitch), findsNothing, reason: 'Top bar must be absent in immersive fullscreen');

      // 4. Exit fullscreen: Top bar present again
      await tester.tap(find.byIcon(Icons.fullscreen_exit_rounded));
      await tester.pump();
      expect(find.byType(OrientationModeSwitch), findsOneWidget, reason: 'Top bar restored after exiting fullscreen');
    });
  });

  group('Prompt F12 — Shield Region Coverage & Opaque Touch Blocking Tests', () {
    testWidgets('KidEmbedPlayer: Top and bottom shields cover full chrome bounds with opaque gesture detectors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 240,
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

      // Locate top shield Positioned
      final topShieldPositioned = tester.widgetList<Positioned>(
        find.descendant(of: find.byType(KidEmbedPlayer), matching: find.byType(Positioned)),
      ).firstWhere((p) => p.top == 0.0 && p.left == 0.0 && p.right == 0.0);

      expect(topShieldPositioned.top, equals(0.0), reason: 'Top shield must align flush to top (top: 0)');
      expect(topShieldPositioned.left, equals(0.0), reason: 'Top shield must align flush to left (left: 0)');
      expect(topShieldPositioned.right, equals(0.0), reason: 'Top shield must stretch flush to right (right: 0)');
      expect(topShieldPositioned.height, greaterThanOrEqualTo(50.0), reason: 'Top shield must be at least 50px high');

      // Locate bottom shield Positioned
      final bottomShieldPositioned = tester.widgetList<Positioned>(
        find.descendant(of: find.byType(KidEmbedPlayer), matching: find.byType(Positioned)),
      ).firstWhere((p) => p.bottom == 0.0 && p.left == 0.0 && p.right == 0.0);

      expect(bottomShieldPositioned.bottom, equals(0.0), reason: 'Bottom shield must align flush to bottom (bottom: 0)');
      expect(bottomShieldPositioned.left, equals(0.0), reason: 'Bottom shield must align flush to left (left: 0)');
      expect(bottomShieldPositioned.right, equals(0.0), reason: 'Bottom shield must stretch flush to right (right: 0)');
      expect(bottomShieldPositioned.height, greaterThanOrEqualTo(50.0), reason: 'Bottom shield must be at least 50px high');

      // Verify all shield gesture detectors have HitTestBehavior.opaque
      final gestureDetectors = tester.widgetList<GestureDetector>(
        find.descendant(of: find.byType(KidEmbedPlayer), matching: find.byType(GestureDetector)),
      ).toList();

      expect(gestureDetectors.length, greaterThanOrEqualTo(2), reason: 'Must contain top shield and watermark tap blockers');
      for (final gd in gestureDetectors) {
        expect(gd.behavior, equals(HitTestBehavior.opaque),
            reason: 'Shield GestureDetector must have HitTestBehavior.opaque to prevent taps escaping into iframe');
      }

      // Verify bottom-right YouTube watermark blocker dimensions
      final watermarkBlocker = tester.widgetList<Positioned>(
        find.descendant(of: find.byType(KidEmbedPlayer), matching: find.byType(Positioned)),
      ).firstWhere((p) => p.bottom == 0.0 && p.right == 0.0 && p.width != null);

      expect(watermarkBlocker.width, greaterThanOrEqualTo(75.0), reason: 'Watermark tap blocker must cover YouTube logo width');
      expect(watermarkBlocker.height, greaterThanOrEqualTo(50.0), reason: 'Watermark tap blocker must cover YouTube logo height');
    });
  });

  group('Prompt F12 & F3 — Fullscreen Save/Restore Round-Trip Tests (Both Entry Paths)', () {
    testWidgets('Entry Path 1 (Top Bar): Saves auto orientation mode and restores on exit', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.auto);
      expect(provider.orientationMode, equals(AppOrientationMode.auto));

      final video = createTestVideo(needsEmbed: true);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(400, 800)));
      await tester.pump();

      // Top bar fullscreen button
      final topBarFsButton = find.byTooltip('Landscape Fullscreen');
      expect(topBarFsButton, findsOneWidget);

      // Tap fullscreen
      await tester.tap(topBarFsButton);
      await tester.pump();

      // Mode switched to landscape and immersive fullscreen active
      expect(provider.orientationMode, equals(AppOrientationMode.landscape));
      expect(find.byType(OrientationModeSwitch), findsNothing);
      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);

      // Exit fullscreen
      await tester.tap(find.byIcon(Icons.fullscreen_exit_rounded));
      await tester.pump();

      // Verify original auto mode is restored cleanly
      expect(provider.orientationMode, equals(AppOrientationMode.auto),
          reason: 'F3 Acceptance: auto mode must survive top-bar fullscreen round-trip');
      expect(find.byType(OrientationModeSwitch), findsOneWidget);
    });

    testWidgets('Entry Path 2 (Portrait Controls): Saves auto orientation mode and restores on exit', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.auto);
      expect(provider.orientationMode, equals(AppOrientationMode.auto));

      // Video with direct MP4 playback has portrait controls
      final video = createTestVideo(needsEmbed: false);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(400, 800)));
      await tester.pump();

      // Find the portrait controls fullscreen button (bottom-right of video surface, no tooltip, size 24)
      final portraitFsButton = find.byWidgetPredicate(
        (widget) => widget is IconButton &&
            widget.tooltip == null &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.fullscreen_rounded,
      );
      expect(portraitFsButton, findsOneWidget, reason: 'Portrait controls expand button must be visible in MP4 portrait mode');

      // Tap portrait controls fullscreen button
      await tester.tap(portraitFsButton);
      await tester.pump();

      // Mode switched to landscape and immersive fullscreen active
      expect(provider.orientationMode, equals(AppOrientationMode.landscape));
      expect(find.byType(OrientationModeSwitch), findsNothing);
      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);

      // Exit fullscreen
      await tester.tap(find.byIcon(Icons.fullscreen_exit_rounded));
      await tester.pump();

      // Verify original auto mode is restored cleanly
      expect(provider.orientationMode, equals(AppOrientationMode.auto),
          reason: 'F3 Acceptance: auto mode must survive portrait-controls fullscreen round-trip');
      expect(find.byType(OrientationModeSwitch), findsOneWidget);
    });

    testWidgets('PopScope back gesture: Restores saved orientation mode when exiting immersive fullscreen', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = TestFakeDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setOrientationMode(AppOrientationMode.auto);

      final video = createTestVideo(needsEmbed: true);
      await tester.pumpWidget(buildTestApp(provider: provider, video: video, screenSize: const Size(400, 800)));
      await tester.pump();

      // Tap fullscreen on top bar
      await tester.tap(find.byTooltip('Landscape Fullscreen'));
      await tester.pump();
      expect(provider.orientationMode, equals(AppOrientationMode.landscape));

      // Trigger pop route (simulating Android back button or system back gesture)
      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue, reason: 'PopScope must intercept back event and exit fullscreen');
      await tester.pump();

      // Verify restored to auto mode
      expect(provider.orientationMode, equals(AppOrientationMode.auto),
          reason: 'Back gesture in fullscreen must restore orientation mode to auto');
      expect(find.byType(OrientationModeSwitch), findsOneWidget);
    });
  });
}
