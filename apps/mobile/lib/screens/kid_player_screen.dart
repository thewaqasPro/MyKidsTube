import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/video_item.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/touch_lock_overlay.dart';
import '../widgets/video_card.dart';
import '../widgets/kid_embed_player.dart';
import '../widgets/orientation_mode_switch.dart';
import 'kid_shorts_feed_screen.dart';

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
  Timer? _watchTrackerTimer;
  int _accumulatedSessionSeconds = 0;
  bool _isMuted = false;
  bool _useEmbed = false;
  bool _isImmersiveLandscape = false;
  bool _didInitOrientation = false;
  AppOrientationMode _savedOrientationMode = AppOrientationMode.auto;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;

    // Enforce layout: If a short video is passed, immediately redirect to vertical shorts feed
    if (widget.video.isShort) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final provider = Provider.of<AppProvider>(context, listen: false);
          final shorts = (widget.playlist.isNotEmpty ? widget.playlist : provider.allVideos)
              .where((v) => v.isShort)
              .toList();
          final feed = shorts.isNotEmpty ? shorts : [widget.video];
          final idx = feed.indexWhere((v) => v.id == widget.video.id);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => KidShortsFeedScreen(
                videos: feed,
                initialIndex: idx >= 0 ? idx : 0,
              ),
            ),
          );
        }
      });
      return;
    }

    // Note: Orientation is initialized in didChangeDependencies according to the user's AppOrientationMode
    WakelockPlus.enable();

    _startWatchTracker();
    _initControllerForVideo(_currentVideo);
  }

  void _startWatchTracker() {
    _watchTrackerTimer?.cancel();
    _watchTrackerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final isPlaying = (_controller != null && _controller!.value.isInitialized && _controller!.value.isPlaying) || _useEmbed;
      if (isPlaying) {
        _accumulatedSessionSeconds += 1;
        if (_accumulatedSessionSeconds >= 300) {
          _flushWatchSession();
        }
      }
    });
  }

  void _flushWatchSession({bool isAtVideoEnd = false}) {
    if (_accumulatedSessionSeconds > 0) {
      final secs = _accumulatedSessionSeconds;
      _accumulatedSessionSeconds = 0;
      final duration = _currentVideo.duration;
      final isSkipped = secs < 10;
      final isCompleted = isAtVideoEnd || (duration > 0 && secs >= (duration * 0.75).round());
      try {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.recordWatchSession(
          videoId: _currentVideo.id,
          videoTitle: _currentVideo.title,
          categoryId: _currentVideo.categoryId,
          secondsWatched: secs,
          videoDuration: duration,
          isCompleted: isCompleted,
          isSkipped: isSkipped,
        );
      } catch (_) {}
    }
  }

  bool _isAutoAdvancing = false;

  Future<void> _initControllerForVideo(VideoItem video, {bool forceEmbed = false}) async {
    _flushWatchSession();
    _hideControlsTimer?.cancel();
    _isAutoAdvancing = false;
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    _controller = null;

    final hasLocal = video.localFilePath != null && File(video.localFilePath!).existsSync();
    final shouldEmbed = forceEmbed || (!hasLocal && video.needsEmbed);

    setState(() {
      _currentVideo = video;
      _useEmbed = shouldEmbed;
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
      _showControls = true;
    });

    if (shouldEmbed) {
      // In embed mode, KidEmbedPlayer automatically streams via YouTube embed
      return;
    }

    try {
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
      if (video.effectiveYoutubeId.isNotEmpty && !_useEmbed) {
        if (mounted) {
          setState(() {
            _useEmbed = true;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Playback error: $e';
          });
        }
      }
    }
  }

  DateTime? _lastPlayerTickTime;
  void _playerListener() {
    if (!mounted || _controller == null) return;
    final val = _controller!.value;
    if (val.isInitialized &&
        !val.isPlaying &&
        !_isAutoAdvancing &&
        val.position >= (val.duration - const Duration(milliseconds: 600)) &&
        val.duration > const Duration(seconds: 3)) {
      _isAutoAdvancing = true;
      _flushWatchSession(isAtVideoEnd: true);
      _playNextVideo();
      return;
    }
    // Throttle progress updates to ~4Hz (250ms) to prevent per-tick UI jank
    final now = DateTime.now();
    if (_lastPlayerTickTime == null || now.difference(_lastPlayerTickTime!).inMilliseconds >= 250) {
      _lastPlayerTickTime = now;
      setState(() {});
    }
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_isInitialized) return;
    final current = _controller!.value.position;
    final total = _controller!.value.duration;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero ? Duration.zero : (target > total ? total : target);
    _controller!.seekTo(clamped);
    _resetControlsTimer();
  }

  void _playNextVideo() {
    final provider = context.read<AppProvider>();
    final list = (widget.playlist.isNotEmpty ? widget.playlist : provider.allVideos)
        .where((v) => !v.isShort)
        .toList();
    final currentIndex = list.indexWhere((v) => v.id == _currentVideo.id);
    if (currentIndex != -1 && currentIndex < list.length - 1) {
      _initControllerForVideo(list[currentIndex + 1]);
    } else if (list.isNotEmpty && list.first.id != _currentVideo.id) {
      _initControllerForVideo(list.first);
    }
  }

  void _playPreviousVideo() {
    final provider = context.read<AppProvider>();
    final list = (widget.playlist.isNotEmpty ? widget.playlist : provider.allVideos)
        .where((v) => !v.isShort)
        .toList();
    final currentIndex = list.indexWhere((v) => v.id == _currentVideo.id);
    if (currentIndex > 0) {
      _initControllerForVideo(list[currentIndex - 1]);
    }
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

  void _toggleOrientation({required bool toLandscape}) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (toLandscape) {
      provider.setOrientationMode(AppOrientationMode.landscape);
    } else {
      provider.setOrientationMode(AppOrientationMode.portrait);
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
    WakelockPlus.disable();
    _hideControlsTimer?.cancel();
    _watchTrackerTimer?.cancel();
    _flushWatchSession();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();

    // Restore orientation based on the active preference
    switch (_savedOrientationMode) {
      case AppOrientationMode.portrait:
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        break;
      case AppOrientationMode.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case AppOrientationMode.auto:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Orientation? _lastOrientation;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _savedOrientationMode = provider.orientationMode;
    if (!_didInitOrientation) {
      _didInitOrientation = true;
      provider.applyCurrentOrientationMode();
    }

    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      if (orientation == Orientation.landscape) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final provider = context.watch<AppProvider>();
    _savedOrientationMode = provider.orientationMode;
    final isLandscape = orientation == Orientation.landscape || provider.orientationMode == AppOrientationMode.landscape;

    if (isLandscape) {
      if (_isImmersiveLandscape) {
        return _buildLandscapeFullscreen(context);
      } else {
        return _buildLandscapeSplitPlayer(context);
      }
    } else {
      return _buildPortraitInlinePlayer(context);
    }
  }

  // ==========================================
  // 1b. LANDSCAPE SPLIT-SCREEN PLAYER (FULL-HEIGHT WITH LEFT RAIL & THUMBNAILS)
  // ==========================================
  Widget _buildLandscapeSplitPlayer(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isFavorite = provider.isFavorite(_currentVideo.id);
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;

    final relatedVideos = (widget.playlist.isNotEmpty ? widget.playlist : provider.allVideos)
        .where((v) => v.id != _currentVideo.id && !v.isShort)
        .toList();

    return PopScope(
      canPop: !_isLocked,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  const leftRailWidth = 46.0;
                  final availableWidth = constraints.maxWidth - leftRailWidth;
                  // Video plays full height, so natural width for 16:9 is height * (16 / 9).
                  // Leave comfortable space for vertical thumbnail cards column.
                  final naturalVideoWidth = constraints.maxHeight * (16 / 9);
                  final maxVideoWidth = (availableWidth - 130.0).clamp(200.0, availableWidth * 0.78);
                  final videoWidth = naturalVideoWidth.clamp(200.0, maxVideoWidth);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. LEFT SIDE: Compact Vertical Toolbar (Moved from Top Bar)
                      Container(
                        width: leftRailWidth,
                        decoration: const BoxDecoration(
                          color: KidColors.bgDark,
                          border: Border(
                            right: BorderSide(color: KidColors.borderDark, width: 0.8),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              // Back button
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                                tooltip: 'Back',
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(height: 2),
                              // Compact Icon Orientation Mode Switcher
                              const OrientationModeSwitch(),
                              const SizedBox(height: 2),
                              // Immersive Fullscreen Button
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                tooltip: 'Full Bleed Video',
                                onPressed: () => setState(() => _isImmersiveLandscape = true),
                              ),
                              const SizedBox(height: 2),
                              // Lock Screen Button
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                                tooltip: 'Lock Screen',
                                onPressed: () => setState(() {
                                  _isLocked = true;
                                  _showControls = false;
                                }),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 22,
                                height: 0.8,
                                color: KidColors.borderDark,
                              ),
                              const SizedBox(height: 4),
                              // Star / Favorite Button
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: isFavorite ? KidColors.yellow : Colors.white,
                                  size: 20,
                                ),
                                tooltip: isFavorite ? 'Starred' : 'Star',
                                onPressed: () => provider.toggleFavorite(_currentVideo.id),
                              ),
                              const SizedBox(height: 2),
                              // Sound Mute Toggle
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                  color: _isMuted ? KidColors.primary : Colors.white,
                                  size: 20,
                                ),
                                tooltip: _isMuted ? 'Muted' : 'Sound',
                                onPressed: _toggleMute,
                              ),
                              const SizedBox(height: 2),
                              // Direct MP4 vs Web Embed Toggle
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  _useEmbed ? Icons.bolt_rounded : Icons.public_rounded,
                                  color: _useEmbed ? KidColors.yellow : Colors.white,
                                  size: 20,
                                ),
                                tooltip: _useEmbed ? 'Switch to MP4' : 'Switch to Embed',
                                onPressed: () {
                                  _initControllerForVideo(_currentVideo, forceEmbed: !_useEmbed);
                                },
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),

                      // 2. MIDDLE: Full Height Video Player (No top bar, no bottom bar)
                      SizedBox(
                        width: videoWidth,
                        height: constraints.maxHeight,
                        child: Container(
                          color: Colors.black,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Center(
                                child: _useEmbed
                                    ? KidEmbedPlayer(
                                        youtubeId: _currentVideo.effectiveYoutubeId,
                                        autoPlay: true,
                                      )
                                    : (_isInitialized
                                        ? AspectRatio(
                                            aspectRatio: _controller!.value.aspectRatio,
                                            child: VideoPlayer(_controller!),
                                          )
                                        : (_hasError
                                            ? _buildPendingOrErrorState()
                                            : const CircularProgressIndicator(color: KidColors.primary))),
                              ),

                              // Tap Detector (direct MP4 mode only)
                              if (!_isLocked && !_useEmbed)
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _toggleControls,
                                  ),
                                ),

                              // Split Controls Overlay
                              if (_showControls && !_isLocked && !_useEmbed)
                                _buildSplitPlayerControls(position, duration),

                              // Scrubber Bar directly along bottom of video player
                              if (!_useEmbed)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: _buildRedScrubber(position, duration),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Vertical Divider
                      Container(width: 1, color: KidColors.borderDark),

                      // 3. RIGHT SIDE: Remaining Space for Video Thumbnails
                      Expanded(
                        child: Container(
                          color: KidColors.canvasDark,
                          child: relatedVideos.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No more videos',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      color: KidColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  itemCount: relatedVideos.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final item = relatedVideos[index];
                                    return _buildLandscapeVideoCard(item);
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
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
      ),
    );
  }

  Widget _buildSplitPlayerControls(Duration position, Duration duration) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
              onPressed: _playPreviousVideo,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
              onPressed: () => _seekRelative(-10),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
              onPressed: () => _seekRelative(10),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
              onPressed: _playNextVideo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeVideoCard(VideoItem item) {
    final title = item.title.contains('•') ? item.title.split('•').last.trim() : item.title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _initControllerForVideo(item),
        child: Container(
          decoration: BoxDecoration(
            color: KidColors.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KidColors.borderDark, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 16:9 Thumbnail Image taking full card width
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Colors.black26),
                      ),
                      if (item.durationFormatted.isNotEmpty)
                        Positioned(
                          bottom: 3,
                          right: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: KidColors.durationBadgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.durationFormatted,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Video Title at the very bottom, clamped to two lines in small text (No channel icons, no sidebar text)
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: KidColors.textLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              child: _useEmbed
                  ? KidEmbedPlayer(
                      youtubeId: _currentVideo.effectiveYoutubeId,
                      autoPlay: true,
                    )
                  : (_isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : (_hasError
                          ? _buildPendingOrErrorState()
                          : const CircularProgressIndicator(color: KidColors.primary))),
            ),

            // Tap detector (direct MP4 mode only)
            if (!_isLocked && !_useEmbed)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControls,
                ),
              ),

            // In embed mode, floating exit-fullscreen button
            if (_useEmbed && !_isLocked)
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => setState(() => _isImmersiveLandscape = false),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),

            // Controls Overlay (direct MP4 mode only)
            if (_showControls && !_isLocked && !_useEmbed) _buildLandscapeControls(context),

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
      color: Colors.black.withValues(alpha: 0.45),
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
                    onPressed: () => setState(() => _isImmersiveLandscape = false),
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

            // Center Controls (Skip Prev, Replay 10, Play/Pause, Forward 10, Skip Next)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                  onPressed: _playPreviousVideo,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 36),
                  onPressed: () => _seekRelative(-10),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 36),
                  onPressed: () => _seekRelative(10),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                  onPressed: _playNextVideo,
                ),
              ],
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
                        onPressed: () => setState(() => _isImmersiveLandscape = false),
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

    final relatedVideos = (widget.playlist.isNotEmpty ? widget.playlist : provider.allVideos)
        .where((v) => v.id != _currentVideo.id && !v.isShort)
        .toList();

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
                        child: _useEmbed
                            ? KidEmbedPlayer(
                                youtubeId: _currentVideo.effectiveYoutubeId,
                                autoPlay: true,
                              )
                            : (_isInitialized
                                ? VideoPlayer(_controller!)
                                : (_hasError
                                    ? _buildPendingOrErrorState()
                                    : const CircularProgressIndicator(color: KidColors.primary))),
                      ),
                    ),

                    // Tap to toggle controls (direct MP4 mode only)
                    if (!_isLocked && !_useEmbed)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleControls,
                        ),
                      ),

                    // In embed mode: floating dismiss down arrow at top-left
                    if (_useEmbed && !_isLocked)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ),

                    // Inline Controls Overlay (direct MP4 mode only)
                    if (_showControls && !_isLocked && !_useEmbed)
                      Container(
                        color: Colors.black.withValues(alpha: 0.4),
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
                            // Top right orientation mode switch
                            const Positioned(
                              top: 6,
                              right: 6,
                              child: OrientationModeSwitch(),
                            ),
                            // Center Controls: Rewind 10, Play/Pause, Forward 10
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                                    onPressed: () => _seekRelative(-10),
                                  ),
                                  const SizedBox(width: 14),
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  IconButton(
                                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                                    onPressed: () => _seekRelative(10),
                                  ),
                                ],
                              ),
                            ),
                            // Bottom Right Fullscreen Icon
                            Positioned(
                              bottom: 12,
                              right: 8,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                                onPressed: () {
                                  _toggleOrientation(toLandscape: true);
                                  setState(() => _isImmersiveLandscape = false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Red Scrubber Bar at bottom of video (direct MP4 mode only)
                    if (!_useEmbed)
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

                    // Metadata & Stream Mode Row
                    Row(
                      children: [
                        Text(
                          _useEmbed
                              ? 'YouTube Kids Safe Embed'
                              : '${_formatDuration(position)} / ${_formatDuration(duration)} • ${_currentVideo.quality}${_currentVideo.fileSizeBytes > 0 ? " • ${(_currentVideo.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB" : ""}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: KidColors.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _useEmbed ? KidColors.primary.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _useEmbed ? KidColors.primary : Colors.green,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _useEmbed ? Icons.tv_rounded : Icons.bolt_rounded,
                                size: 12,
                                color: _useEmbed ? KidColors.primary : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _useEmbed ? 'Embed' : 'Direct Stream',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _useEmbed ? KidColors.primary : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          // Toggle Mode (Embed vs MP4)
                          _buildPillButton(
                            icon: _useEmbed ? Icons.bolt_rounded : Icons.public_rounded,
                            iconColor: _useEmbed ? KidColors.yellow : Colors.white,
                            label: _useEmbed ? 'Try Direct MP4' : 'YouTube Embed',
                            onTap: () {
                              _initControllerForVideo(_currentVideo, forceEmbed: !_useEmbed);
                            },
                          ),
                          const SizedBox(width: 10),

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

                          // Kids Landscape Mode
                          _buildPillButton(
                            icon: Icons.stay_current_landscape_rounded,
                            iconColor: KidColors.accent,
                            label: 'Kids Landscape',
                            onTap: () {
                              _toggleOrientation(toLandscape: true);
                              setState(() => _isImmersiveLandscape = false);
                            },
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

  Widget _buildPendingOrErrorState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_currentVideo.thumbnailUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: _currentVideo.thumbnailUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: const Color(0xFF18181B)),
          ),
        Container(
          color: Colors.black.withValues(alpha: 0.72),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: KidColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: KidColors.primary, size: 32),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Video Queued for Sync',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage.isNotEmpty ? _errorMessage : 'High-definition file is syncing to media storage.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KidColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => _initControllerForVideo(_currentVideo, forceEmbed: true),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Play via Embed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _playNextVideo,
                      icon: const Icon(Icons.skip_next_rounded, size: 18),
                      label: const Text('Next Video', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
        overlayColor: KidColors.primary.withValues(alpha: 0.3),
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
