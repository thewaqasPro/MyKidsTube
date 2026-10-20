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
import 'package:safe_tube/services/infinite_video_queue.dart';

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
  ) => TestWebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => TestWebViewWidget(params);
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

VideoItem createTestVideo(String id) {
  return VideoItem(
    id: id,
    title: 'Title $id',
    categoryId: 'learning',
    sourceUrl: 'https://youtube.com/watch?v=$id',
    duration: 120,
    streamUrl: 'https://example.com/$id.mp4',
    thumbnailUrl: 'https://example.com/$id.jpg',
    status: 'ready',
    youtubeId: id,
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

  testWidgets('KidPlayerScreen supports infinite scrolling both UP and DOWN seamlessly', (tester) async {
    final v0 = createTestVideo('vid_0');
    final v1 = createTestVideo('vid_1');
    final v2 = createTestVideo('vid_2');
    final playlist = [v0, v1, v2];

    final db = TestFakeDatabaseService();
    final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(500, 900),
              padding: EdgeInsets.zero,
            ),
            child: KidPlayerScreen(
              video: v1, // Starts at v1 (index 1 of 3)
              playlist: playlist,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Initial page should be at kInitialPageIndex (10000)
    final pageViewFinder = find.byType(PageView);
    expect(pageViewFinder, findsOneWidget);
    final pageView = tester.widget<PageView>(pageViewFinder);
    final controller = pageView.controller!;
    expect(controller.initialPage, equals(InfiniteVideoQueue.kInitialPageIndex));
    expect(controller.page?.round(), equals(10000));

    // Scroll DOWN -> advances to 10001
    controller.jumpToPage(10001);
    await tester.pump();
    expect(controller.page?.round(), equals(10001));

    // Scroll UP -> goes back to 10000
    controller.jumpToPage(10000);
    await tester.pump();
    expect(controller.page?.round(), equals(10000));

    // Scroll UP again -> goes to 9999 (scrolling up beyond start!)
    controller.jumpToPage(9999);
    await tester.pump();
    expect(controller.page?.round(), equals(9999));

    // Scroll UP again -> wraps infinitely backward to 9998!
    controller.jumpToPage(9998);
    await tester.pump();
    expect(controller.page?.round(), equals(9998));
  });
}
