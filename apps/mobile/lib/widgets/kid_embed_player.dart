import 'dart:async';
import 'dart:ui';
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
  final double scale;
  final double zoom;
  final Color shieldColor;
  final double? topShieldHeight;
  final double? bottomShieldHeight;

  const KidEmbedPlayer({
    super.key,
    required this.youtubeId,
    this.autoPlay = true,
    this.aspectRatio,
    this.scale = 1.0,
    this.zoom = 1.0,
    this.shieldColor = KidColors.canvasDark,
    this.topShieldHeight,
    this.bottomShieldHeight,
  });

  @override
  State<KidEmbedPlayer> createState() => _KidEmbedPlayerState();
}

class _KidEmbedPlayerState extends State<KidEmbedPlayer> {
  late final WebViewController _controller;
  double _currentPlaybackSeconds = 0.0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showShields = true;
  Timer? _shieldDismissTimer;
  Timer? _playRetryTimer1;
  Timer? _playRetryTimer2;

  @override
  void initState() {
    super.initState();
    _initController();
    _scheduleShieldDismiss();
  }

  @override
  void dispose() {
    _playRetryTimer1?.cancel();
    _playRetryTimer2?.cancel();
    _shieldDismissTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(KidEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.youtubeId != widget.youtubeId) {
      _currentPlaybackSeconds = 0.0;
      _loadVideo(widget.youtubeId);
    }
  }

  void _onUserInteraction() {
    if (!mounted) return;
    if (!_showShields) {
      setState(() => _showShields = true);
    }
    _scheduleShieldDismiss();
  }

  void _scheduleShieldDismiss() {
    _shieldDismissTimer?.cancel();
    _shieldDismissTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _showShields) {
        setState(() => _showShields = false);
      }
    });
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
      ..addJavaScriptChannel(
        'KidsTubeBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          final t = double.tryParse(msg.message);
          if (t != null && t > 0) {
            _currentPlaybackSeconds = t;
          }
        },
      )
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
              _onUserInteraction();
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
          frame.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', 'https://www.youtube-nocookie.com');
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
    _shieldDismissTimer?.cancel();

    if (mounted) {
      setState(() {
        _hasError = false;
        _isLoading = true;
        _showShields = true;
      });
    }
    _scheduleShieldDismiss();

    final autoPlayFlag = widget.autoPlay ? 1 : 0;
    final startParam = _currentPlaybackSeconds > 2 ? '&start=${_currentPlaybackSeconds.toInt()}' : '';
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
      width: ${widget.zoom != 1.0 ? '${(100 / widget.zoom).toStringAsFixed(1)}%' : '100%'};
      height: ${widget.zoom != 1.0 ? '${(100 / widget.zoom).toStringAsFixed(1)}%' : '100%'};
      border: 0;
      ${widget.zoom != 1.0 ? 'zoom: ${widget.zoom};' : ''}
      ${widget.scale != 1.0 ? 'transform: scale(${widget.scale}); transform-origin: center center;' : ''}
    }
  </style>
</head>
<body>
  <iframe
    id="player"
    src="https://www.youtube-nocookie.com/embed/$id?autoplay=$autoPlayFlag$startParam&controls=0&playsinline=1&modestbranding=1&rel=0&iv_load_policy=3&disablekb=1&enablejsapi=1&origin=https://www.youtube-nocookie.com"
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
          frame.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', 'https://www.youtube-nocookie.com');
        }
      } catch(e) {}
    }

    setInterval(function() {
      try {
        if (window.player && typeof window.player.getCurrentTime === 'function') {
          var t = window.player.getCurrentTime();
          if (t && t > 0 && window.KidsTubeBridge) {
            window.KidsTubeBridge.postMessage(t.toString());
          }
        }
      } catch(e) {}
    }, 1000);

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
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        // True for compact players (like standard 16:9 portrait player where height is ~200-240px)
        final isCompact = constraints.maxHeight < 280;
        final topHeight = widget.topShieldHeight ?? (isCompact ? 50.0 : 55.0);
        final bottomHeight = widget.bottomShieldHeight ?? (isCompact ? 50.0 : 60.0);
        final blurSigma = isCompact ? 14.0 : 20.0;
        final logoWidth = isCompact ? 75.0 : 90.0;

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _onUserInteraction(),
          child: Stack(
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

              // 4. SHIELD 1: Dynamic Top Frosted Glass & Gradient Shield
              if (!_hasError)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topHeight,
                  child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: _showShields ? 1.0 : 0.0,
                      duration: _showShields
                          ? const Duration(milliseconds: 30)
                          : const Duration(milliseconds: 250),
                      curve: _showShields ? Curves.linear : Curves.easeOut,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  widget.shieldColor.withValues(alpha: 0.95),
                                  widget.shieldColor.withValues(alpha: 0.70),
                                  widget.shieldColor.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.65, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onUserInteraction,
                    ),
                  ),
                ],
              ),
            ),

              // 5. SHIELD 2: Dynamic Bottom Frosted Glass & Gradient Shield
              if (!_hasError)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: bottomHeight,
                  child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: _showShields ? 1.0 : 0.0,
                      duration: _showShields
                          ? const Duration(milliseconds: 30)
                          : const Duration(milliseconds: 250),
                      curve: _showShields ? Curves.linear : Curves.easeOut,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  widget.shieldColor.withValues(alpha: 0.95),
                                  widget.shieldColor.withValues(alpha: 0.70),
                                  widget.shieldColor.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.65, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                      // Bottom-right watermark tap blocker (YouTube logo)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        width: logoWidth,
                        height: bottomHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onUserInteraction,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
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
