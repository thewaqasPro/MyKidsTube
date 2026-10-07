import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(KidEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.youtubeId != widget.youtubeId || oldWidget.autoPlay != widget.autoPlay) {
      _loadVideo(widget.youtubeId);
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
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

    _loadVideo(widget.youtubeId);
  }

  void _loadVideo(String id) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; }
    html, body {
      margin: 0;
      padding: 0;
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
    }
  </style>
</head>
<body>
  <iframe
    id="player"
    src="https://www.youtube-nocookie.com/embed/$id?autoplay=${widget.autoPlay ? 1 : 0}&playsinline=1&modestbranding=1&rel=0&iv_load_policy=3&controls=1&fs=1"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
    allowfullscreen>
  </iframe>
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
        if (_isLoading)
          Container(
            color: Colors.black,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFFF0000),
                ),
              ),
            ),
          ),

        // 3. SHIELD 1: Top External Link Shield (Blocks external title/avatar taps)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {}, // absorbs tap
          ),
        ),

        // 4. SHIELD 2: Bottom-Right YouTube Logo Shield (Blocks external logo tap)
        Positioned(
          bottom: 0,
          right: 0,
          width: 80,
          height: 46,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {}, // absorbs tap
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
