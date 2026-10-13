import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/widgets/kid_embed_player.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class MuteTestWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return MuteTestPlatformWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MuteTestPlatformWebViewWidget(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return MuteTestPlatformNavigationDelegate(params);
  }
}

class MuteTestPlatformNavigationDelegate extends PlatformNavigationDelegate {
  MuteTestPlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback onNavigationRequest) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback onWebResourceError) async {}
}

class MuteTestPlatformWebViewController extends PlatformWebViewController {
  MuteTestPlatformWebViewController(super.params) : super.implementation();

  String? loadedHtml;
  String? lastJavaScript;

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    loadedHtml = html;
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {}

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams javaScriptChannelParams) async {}

  @override
  Future<void> runJavaScript(String javaScript) async {
    lastJavaScript = javaScript;
  }
}

class MuteTestPlatformWebViewWidget extends PlatformWebViewWidget {
  MuteTestPlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

void main() {
  setUpAll(() {
    WebViewPlatform.instance = MuteTestWebViewPlatform();
  });

  group('KidEmbedPlayer Mute Functionality Tests', () {
    test('buildEmbedHtml generates correct &mute=1 when isMuted is true', () {
      final htmlMuted = KidEmbedPlayer.buildEmbedHtml(
        youtubeId: 'test12345',
        autoPlay: true,
        isMuted: true,
      );

      expect(htmlMuted.contains('&mute=1'), isTrue,
          reason: 'Embed iframe URL must specify &mute=1 when isMuted is true');
      expect(htmlMuted.contains('muteVideo()'), isTrue,
          reason: 'Iframe script must define muteVideo() JS helper');
      expect(htmlMuted.contains('unMuteVideo()'), isTrue,
          reason: 'Iframe script must define unMuteVideo() JS helper');
      expect(htmlMuted.contains('event.target.mute()'), isTrue,
          reason: 'onReady callback must mute player when isMuted is true');
    });

    test('buildEmbedHtml generates correct &mute=0 when isMuted is false', () {
      final htmlUnmuted = KidEmbedPlayer.buildEmbedHtml(
        youtubeId: 'test12345',
        autoPlay: true,
        isMuted: false,
      );

      expect(htmlUnmuted.contains('&mute=0'), isTrue,
          reason: 'Embed iframe URL must specify &mute=0 when isMuted is false');
      expect(htmlUnmuted.contains('event.target.mute()'), isFalse,
          reason: 'onReady callback must not mute player when isMuted is false');
    });

    testWidgets('KidEmbedPlayer widget accepts isMuted property and defaults to false', (tester) async {
      const defaultPlayer = KidEmbedPlayer(youtubeId: 'testDefault');
      expect(defaultPlayer.isMuted, isFalse);

      const mutedPlayer = KidEmbedPlayer(youtubeId: 'testMuted', isMuted: true);
      expect(mutedPlayer.isMuted, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: KidEmbedPlayer(
                youtubeId: 'widget_test_1',
                isMuted: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final state = tester.state<KidEmbedPlayerState>(find.byType(KidEmbedPlayer));
      expect(state.currentHtml, isNotNull);
      expect(state.currentHtml!.contains('&mute=1'), isTrue);
    });
  });
}
