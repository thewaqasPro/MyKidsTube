import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/touch_lock_overlay.dart';
import '../widgets/video_card.dart';

/// Authentic YouTube / YouTube Kids Player Screen
class KidPlayerScreen extends StatefulWidget {
  final VideoItem video;
  final List<VideoItem> playlist;

  const KidPlayerScreen({
    super.key,
    required this.video,
    this.playlist = const [],
  });

  @override
  State<KidPlayerScreen> createState() => _KidPlayerScreenState();
}

class _KidPlayerScreenState extends State<KidPlayerScreen> {
  late VideoItem _currentVideo;
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLocked = false;
  bool _showControls = true;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _hideControlsTimer;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;

    // Allow both portrait and landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initControllerForVideo(_currentVideo);
  }

  Future<void> _initControllerForVideo(VideoItem video) async {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();

    setState(() {
      _currentVideo = video;
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
      _showControls = true;
    });

    try {
      final hasLocal = video.localFilePath != null && File(video.localFilePath!).existsSync();
      final ctrl = hasLocal
          ? VideoPlayerController.file(File(video.localFilePath!))
          : VideoPlayerController.networkUrl(Uri.parse(video.streamUrl));

      _controller = ctrl;
      await ctrl.initialize();
      ctrl.addListener(_playerListener);
      ctrl.setVolume(_isMuted ? 0.0 : 1.0);
      ctrl.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _resetControlsTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not load video. Please verify connection.';
        });
      }
    }
  }

  void _playerListener() {
    if (mounted) setState(() {});
  }

  void _resetControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_controller != null && _controller!.value.isPlaying && !_isLocked) {
      _hideControlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _controller!.value.isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetControlsTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _hideControlsTimer?.cancel();
      } else {
        _controller!.play();
        _resetControlsTimer();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _toggleOrientation(bool isLandscape) {
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _channelName {
    if (_currentVideo.channelName != null && _currentVideo.channelName!.isNotEmpty) {
      return _currentVideo.channelName!;
    }
    if (_currentVideo.title.contains('•')) {
      return _currentVideo.title.split('•').first.trim();
    }
    return 'KidsTube';
  }

  String get _cleanTitle {
    if (_currentVideo.title.contains('•')) {
      return _currentVideo.title.split('•').last.trim();
    }
    return _currentVideo.title;
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    if (isLandscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      return _buildLandscapeFullscreen(context);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      return _buildPortraitInlinePlayer(context);
    }
  }

  // ==========================================
  // 1. LANDSCAPE IMMERSIVE FULLSCREEN
  // ==========================================
  Widget _buildLandscapeFullscreen(BuildContext context) {
    return PopScope(
      canPop: !_isLocked,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Video Surface
            Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : const CircularProgressIndicator(color: KidColors.primary),
            ),

            // Tap detector
            if (!_isLocked)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControls,
                ),
              ),

            // Controls Overlay
            if (_showControls && !_isLocked) _buildLandscapeControls(context),

            // Touch Lock Overlay
            TouchLockOverlay(
              isLocked: _isLocked,
              showLockButton: false,
              onLock: () => setState(() {
                _isLocked = true;
                _showControls = false;
              }),
              onUnlock: () => setState(() {
                _isLocked = false;
                _showControls = true;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeControls(BuildContext context) {
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;

    return Container(
      color: Colors.black.withOpacity(0.45),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                    onPressed: () => _toggleOrientation(true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cleanTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white),
                    onPressed: _toggleMute,
                  ),
                  IconButton(
                    icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                    onPressed: () => setState(() {
                      _isLocked = true;
                      _showControls = false;
                    }),
                  ),
                ],
              ),
            ),

            // Center Play / Pause
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ),

            // Bottom Red Scrubber Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRedScrubber(position, duration),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: const TextStyle(fontFamily: 'Roboto', color: Colors.white, fontSize: 12),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 24),
                        onPressed: () => _toggleOrientation(true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. PORTRAIT INLINE PLAYER (YOUTUBE AUTHENTIC)
  // ==========================================
  Widget _buildPortraitInlinePlayer(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isFavorite = provider.isFavorite(_currentVideo.id);
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;

    final relatedVideos = widget.playlist.isNotEmpty
        ? widget.playlist.where((v) => v.id != _currentVideo.id).toList()
        : provider.allVideos.where((v) => v.id != _currentVideo.id).toList();

    return PopScope(
      canPop: !_isLocked,
      child: Scaffold(
        backgroundColor: KidColors.bgDark,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Anchored 16:9 Inline Video Player
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: _isInitialized
                            ? VideoPlayer(_controller!)
                            : (_hasError
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: KidColors.primary, size: 36),
                                        const SizedBox(height: 8),
                                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      ],
                                    ),
                                  )
                                : const CircularProgressIndicator(color: KidColors.primary)),
                      ),
                    ),

                    // Tap to toggle controls
                    if (!_isLocked)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleControls,
                        ),
                      ),

                    // Inline Controls Overlay
                    if (_showControls && !_isLocked)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: Stack(
                          children: [
                            // Top left back button
                            Positioned(
                              top: 6,
                              left: 6,
                              child: IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            // Center Play / Pause
                            Center(
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                            // Bottom Right Fullscreen Icon
                            Positioned(
                              bottom: 12,
                              right: 8,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                                onPressed: () => _toggleOrientation(false),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Red Scrubber Bar at bottom of video
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildRedScrubber(position, duration),
                    ),

                    // Touch Lock Overlay
                    TouchLockOverlay(
                      isLocked: _isLocked,
                      showLockButton: false,
                      onLock: () => setState(() {
                        _isLocked = true;
                        _showControls = false;
                      }),
                      onUnlock: () => setState(() {
                        _isLocked = false;
                        _showControls = true;
                      }),
                    ),
                  ],
                ),
              ),

              // 2. Video Details & Actions Underneath (Scrollable)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  children: [
                    // Video Title (FontWeight 500, 16px)
                    Text(
                      _cleanTitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: KidColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Metadata row
                    Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)} • ${_currentVideo.quality}${_currentVideo.fileSizeBytes > 0 ? " • ${(_currentVideo.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB" : ""}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: KidColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Channel Avatar + Name Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: KidColors.primary,
                          backgroundImage: (_currentVideo.channelIconUrl != null && _currentVideo.channelIconUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(_currentVideo.channelIconUrl!)
                              : null,
                          child: (_currentVideo.channelIconUrl != null && _currentVideo.channelIconUrl!.isNotEmpty)
                              ? null
                              : Text(
                                  _channelName.isNotEmpty ? _channelName[0].toUpperCase() : 'K',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _channelName,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: KidColors.textLight,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Single-Row Action Bar (YouTube Pill Buttons)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Star / Favorite
                          _buildPillButton(
                            icon: isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                            iconColor: isFavorite ? KidColors.yellow : Colors.white,
                            label: isFavorite ? 'Starred' : 'Favorite',
                            onTap: () => provider.toggleFavorite(_currentVideo.id),
                          ),
                          const SizedBox(width: 10),

                          // Mute / Sound
                          _buildPillButton(
                            icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            iconColor: _isMuted ? KidColors.primary : Colors.white,
                            label: _isMuted ? 'Muted' : 'Sound',
                            onTap: _toggleMute,
                          ),
                          const SizedBox(width: 10),

                          // Fullscreen
                          _buildPillButton(
                            icon: Icons.fullscreen_rounded,
                            iconColor: Colors.white,
                            label: 'Landscape',
                            onTap: () => _toggleOrientation(false),
                          ),
                          const SizedBox(width: 10),

                          // Toddler Lock
                          _buildPillButton(
                            icon: Icons.lock_outline_rounded,
                            iconColor: Colors.white,
                            label: 'Lock Screen',
                            onTap: () => setState(() {
                              _isLocked = true;
                              _showControls = false;
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: KidColors.borderDark, height: 1),
                    const SizedBox(height: 16),

                    // "Up Next / More Videos" Header
                    const Text(
                      'More for Kids',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: KidColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List of more curated parent-approved videos
                    ...relatedVideos.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: VideoCard(
                            video: item,
                            onTap: () => _initControllerForVideo(item),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sleek YouTube Red Scrubber Bar
  Widget _buildRedScrubber(Duration position, Duration duration) {
    final maxMs = duration.inMilliseconds.toDouble();
    final currentMs = position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: KidColors.primary, // Signature YouTube Red #FF0000
        inactiveTrackColor: Colors.white24,
        thumbColor: KidColors.primary,
        overlayColor: KidColors.primary.withOpacity(0.3),
      ),
      child: Slider(
        value: currentMs,
        min: 0.0,
        max: maxMs > 0 ? maxMs : 1.0,
        onChanged: (val) {
          _controller?.seekTo(Duration(milliseconds: val.toInt()));
        },
      ),
    );
  }

  /// YouTube Standard Pill Button (18px radius)
  Widget _buildPillButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: KidColors.surfaceDark,
          borderRadius: BorderRadius.circular(18), // 18px radius per DESIGN.md
          border: Border.all(color: KidColors.borderDark, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 19),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: KidColors.textLight,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
