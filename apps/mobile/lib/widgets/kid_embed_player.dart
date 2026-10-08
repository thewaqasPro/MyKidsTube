import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../utils/constants.dart';

/// Kid-Safe YouTube Embed Player Widget for Mobile
/// Runs a sandboxed YouTube embed with child-protective shields
/// preventing navigation away from the app.
class KidEmbedPlayer extends StatefulWidget {
  final String youtubeId;
  final bool autoPlay;
  final double? aspectRatio;

  const KidEmbedPlayer({
    super.key,
    required this.youtubeId,
    this.autoPlay = true,
    this.aspectRatio,
  });

  @override
  State<KidEmbedPlayer> createState() => _KidEmbedPlayerState();
}

class _KidEmbedPlayerState extends State<KidEmbedPlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _playRetryTimer1;
  Timer? _playRetryTimer2;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void dispose() {
    _playRetryTimer1?.cancel();
    _playRetryTimer2?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(KidEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.youtubeId != widget.youtubeId || oldWidget.autoPlay != widget.autoPlay) {
      _loadVideo(widget.youtubeId);
    }
  }

  void _initController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
              if (widget.autoPlay) {
                _sendPlayCommands();
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            // Only permit internal embed playback; block external links
            if (url.contains('youtube-nocookie.com') ||
                url.contains('youtube.com/embed') ||
                url.startsWith('data:') ||
                url.startsWith('about:blank')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _loadVideo(widget.youtubeId);
  }

  void _sendPlayCommands() {
    const jsPlay = '''
      try {
        if (window.player && typeof window.player.playVideo === 'function') {
          window.player.playVideo();
        }
        var frame = document.getElementById('player');
        if (frame && frame.contentWindow) {
          frame.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
        }
      } catch(e) {}
    ''';

    _controller.runJavaScript(jsPlay);

    _playRetryTimer1?.cancel();
    _playRetryTimer1 = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.runJavaScript(jsPlay);
      }
    });

    _playRetryTimer2?.cancel();
    _playRetryTimer2 = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _controller.runJavaScript(jsPlay);
      }
    });
  }

  void _loadVideo(String id) {
    _playRetryTimer1?.cancel();
    _playRetryTimer2?.cancel();

    setState(() {
      _hasError = false;
      _isLoading = true;
    });

    final autoPlayFlag = widget.autoPlay ? 1 : 0;
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      width: 100%;
      height: 100%;
      background-color: #000;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    iframe {
      width: 100%;
      height: 100%;
      border: 0;
      transform: scale(1.14);
      transform-origin: center center;
    }
  </style>
</head>
<body>
  <iframe
    id="player"
    src="https://www.youtube-nocookie.com/embed/$id?autoplay=$autoPlayFlag&playsinline=1&modestbranding=1&rel=0&iv_load_policy=3&controls=0&fs=0&disablekb=1&enablejsapi=1&origin=https://www.youtube-nocookie.com"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowfullscreen>
  </iframe>
  <script>
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

    var player;
    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        events: {
          'onReady': function(event) {
            ${widget.autoPlay ? "try { event.target.playVideo(); } catch(e) {}" : ""}
          }
        }
      });
      window.player = player;
    }

    function sendPlay() {
      try {
        if (window.player && typeof window.player.playVideo === 'function') {
          window.player.playVideo();
        }
        var frame = document.getElementById('player');
        if (frame && frame.contentWindow) {
          frame.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
        }
      } catch(e) {}
    }

    ${widget.autoPlay ? """
    window.addEventListener('load', function() {
      setTimeout(sendPlay, 300);
      setTimeout(sendPlay, 800);
      setTimeout(sendPlay, 1600);
    });
    """ : ""}
  </script>
</body>
</html>
''';
    _controller.loadHtmlString(html, baseUrl: 'https://www.youtube-nocookie.com');
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        // 1. Sandboxed Web Player
        WebViewWidget(controller: _controller),

        // 2. Loading Spinner
        if (_isLoading && !_hasError)
          Container(
            color: Colors.black,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: KidColors.primary,
                ),
              ),
            ),
          ),

        // 3. Error UI with Retry
        if (_hasError)
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: KidColors.red, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'Unable to stream embed.',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KidColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => _loadVideo(widget.youtubeId),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),

        // 4. SHIELD 1: Top External Link Shield
        if (!_hasError)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {},
            ),
          ),

        // 5. SHIELD 2: Bottom-Right YouTube Logo Shield
        if (!_hasError)
          Positioned(
            bottom: 0,
            right: 0,
            width: 80,
            height: 46,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {},
            ),
          ),
      ],
    );

    if (widget.aspectRatio != null) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio!,
        child: content,
      );
    }

    return content;
  }
}
