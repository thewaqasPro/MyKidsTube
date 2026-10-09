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
  bool _wasLandscapeBeforeFullscreen = false;
  AppOrientationMode? _orientationModeBeforeFullscreen;
  bool _didInitOrientation = false;
  AppOrientationMode _savedOrientationMode = AppOrientationMode.auto;
  late final GlobalKey _embedPlayerKey = GlobalKey(debugLabel: 'kid_embed_player');
  late final GlobalKey _nativePlayerKey = GlobalKey(debugLabel: 'kid_native_player');
  String? _selectedRelatedCategory;

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
      _selectedRelatedCategory = null;
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

  void _exitFullscreen() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (_wasLandscapeBeforeFullscreen || provider.orientationMode == AppOrientationMode.landscape) {
      // User was already in landscape before entering fullscreen: retain landscape split view!
      if (_orientationModeBeforeFullscreen != null && provider.orientationMode != _orientationModeBeforeFullscreen) {
        provider.setOrientationMode(_orientationModeBeforeFullscreen!);
      }
    } else {
      // User was initially in portrait mode: restore initial portrait view
      if (_orientationModeBeforeFullscreen != null) {
        provider.setOrientationMode(_orientationModeBeforeFullscreen!);
      } else {
        _toggleOrientation(toLandscape: false);
      }
    }
    setState(() => _isImmersiveLandscape = false);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    final relatedVideos = widget.playlist.isNotEmpty
        ? widget.playlist.where((v) => v.id != _currentVideo.id && !v.isShort).toList()
        : provider.getRecommendationsFor(_currentVideo, filterCategory: _selectedRelatedCategory);

    // 1. Calculate Player Geometry (Dynamic positioning in unified Stack)
    late final double playerLeft;
    late final double playerTop;
    late final double playerWidth;
    late final double playerHeight;

    if (_isImmersiveLandscape) {
      // Fullscreen mode: fills entire screen
      playerLeft = 0;
      playerTop = 0;
      playerWidth = screenSize.width;
      playerHeight = screenSize.height;
    } else if (isLandscape) {
      // Landscape Split mode: occupies left side below top bar
      final availableWidth = screenSize.width - padding.left - padding.right;
      final availableHeight = (screenSize.height - padding.top - padding.bottom - 40.0).clamp(100.0, double.infinity);
      final naturalVideoWidth = availableHeight * (16 / 9);
      final maxVideoWidth = (availableWidth - 140.0).clamp(200.0, availableWidth * 0.76);
      final videoWidth = naturalVideoWidth.clamp(200.0, maxVideoWidth);

      playerLeft = padding.left;
      playerTop = padding.top + 40.0;
      playerWidth = videoWidth;
      playerHeight = availableHeight;
    } else {
      // Portrait mode: occupies full available width below top bar with natural 16:9 ratio
      final effectiveAspectRatio = (_isInitialized && _controller != null && _controller!.value.aspectRatio > 0)
          ? _controller!.value.aspectRatio
          : (_currentVideo.isShort ? (9 / 16) : (16 / 9));
      final availableWidth = screenSize.width - padding.left - padding.right;
      final videoHeight = availableWidth / effectiveAspectRatio;

      playerLeft = padding.left;
      playerTop = padding.top + 40.0;
      playerWidth = availableWidth;
      playerHeight = videoHeight;
    }

    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;

    return PopScope(
      canPop: !_isLocked && !_isImmersiveLandscape,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isImmersiveLandscape && !_isLocked) {
          _exitFullscreen();
        }
      },
      child: Scaffold(
        backgroundColor: isLandscape ? Colors.black : KidColors.bgDark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ==========================================
            // LAYER 1: VIDEO PLAYER SURFACE (STABLE WIDGET NODE)
            // Stays permanently mounted; never destroyed across rotation/fullscreen
            // ==========================================
            Positioned(
              left: playerLeft,
              top: playerTop,
              width: playerWidth,
              height: playerHeight,
              child: _buildPlayerSurface(),
            ),

            // Controls & scrubber for MP4 direct playback over player surface
            if (!_useEmbed)
              Positioned(
                left: playerLeft,
                top: playerTop,
                width: playerWidth,
                height: playerHeight,
                child: Stack(
                  children: [
                    if (_showControls && !_isLocked)
                      (_isImmersiveLandscape
                          ? _buildLandscapeControls(context)
                          : (isLandscape
                              ? _buildSplitPlayerControls(position, duration)
                              : _buildPortraitControls(position, duration))),
                    if (!_isImmersiveLandscape)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildRedScrubber(position, duration),
                      ),
                  ],
                ),
              ),

            // ==========================================
            // LAYER 2: FIXED TOP BAR (NOT IN FULLSCREEN)
            // ==========================================
            if (!_isLocked && !_isImmersiveLandscape)
              Positioned(
                left: padding.left,
                right: padding.right,
                top: padding.top,
                height: 40.0,
                child: _buildFixedTopBar(context, isLandscape: isLandscape),
              ),

            // ==========================================
            // LAYER 3: PLAYLIST / DETAILS AREA
            // ==========================================
            if (!_isImmersiveLandscape) ...[
              if (isLandscape) ...[
                // Vertical divider
                Positioned(
                  left: playerLeft + playerWidth,
                  top: playerTop,
                  width: 1,
                  height: playerHeight,
                  child: Container(color: KidColors.borderDark),
                ),
                // Landscape Right Playlist
                Positioned(
                  left: playerLeft + playerWidth + 1,
                  top: playerTop,
                  right: padding.right,
                  bottom: padding.bottom,
                  child: _buildLandscapePlaylistSection(relatedVideos),
                ),
              ] else ...[
                // Portrait Bottom Details & Playlist
                Positioned(
                  left: padding.left,
                  top: playerTop + playerHeight,
                  right: padding.right,
                  bottom: padding.bottom,
                  child: _buildPortraitDetailsAndPlaylist(relatedVideos, position, duration),
                ),
              ],
            ],

            // ==========================================
            // LAYER 4: FULLSCREEN FLOATING EXIT BUTTON
            // ==========================================
            if (!_isLocked && _isImmersiveLandscape)
              Positioned(
                top: padding.top + 16,
                left: padding.left + 16,
                child: _buildFullscreenExitButton(),
              ),

            // ==========================================
            // LAYER 5: TOUCH LOCK OVERLAY
            // ==========================================
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

  Widget _buildPlayerSurface() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: _useEmbed
                ? KidEmbedPlayer(
                    key: _embedPlayerKey,
                    youtubeId: _currentVideo.effectiveYoutubeId,
                    autoPlay: true,
                    scale: 1.14,
                  )
                : (_isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(
                          key: _nativePlayerKey,
                          _controller!,
                        ),
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
        ],
      ),
    );
  }

  Widget _buildFullscreenExitButton() {
    return SafeArea(
      child: GestureDetector(
        onTap: _exitFullscreen,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildLandscapePlaylistSection(List<VideoItem> relatedVideos) {
    return Container(
      color: KidColors.canvasDark,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: KidColors.borderDark, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Up Next',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: KidColors.textLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.shuffle_rounded, color: KidColors.primary, size: 16),
                  tooltip: 'Shuffle',
                  onPressed: () {
                    context.read<AppProvider>().reseedRecommendations();
                  },
                ),
              ],
            ),
          ),
          Expanded(
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
        ],
      ),
    );
  }

  Widget _buildPortraitControls(Duration position, Duration duration) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Stack(
        children: [
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
          Positioned(
            bottom: 12,
            right: 8,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
              onPressed: () {
                _toggleOrientation(toLandscape: true);
                setState(() => _isImmersiveLandscape = true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitDetailsAndPlaylist(
    List<VideoItem> relatedVideos,
    Duration position,
    Duration duration,
  ) {
    return Container(
      color: KidColors.bgDark,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          // Video Title (FontWeight 500, 14.5px)
          Text(
            _cleanTitle,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: KidColors.textLight,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Metadata & Stream Mode Row (hidden for embeds where playback time is unavailable)
          if (!_useEmbed) ...[
            Text(
              '${_formatDuration(position)} / ${_formatDuration(duration)} • ${_currentVideo.quality}${_currentVideo.fileSizeBytes > 0 ? " • ${(_currentVideo.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB" : ""}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: KidColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Single-Row Action Bar (Kids Landscape & Lock Screen)
          Row(
            children: [
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

          const SizedBox(height: 16),
          const Divider(color: KidColors.borderDark, height: 1),
          const SizedBox(height: 16),

          // "Up Next / More Videos" Header with Shuffle & Quick Filters
          Row(
            children: [
              const Text(
                'More for Kids',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: KidColors.textLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.read<AppProvider>().reseedRecommendations();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: KidColors.cardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KidColors.borderDark, width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shuffle_rounded, size: 13, color: KidColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Shuffle',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Category Quick-Filters (All Picks vs More [Category])
          if (_currentCategoryName.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRecommendationFilterChip(
                    label: 'All Picks',
                    isSelected: _selectedRelatedCategory == null,
                    onTap: () => setState(() => _selectedRelatedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  _buildRecommendationFilterChip(
                    label: 'More $_currentCategoryName',
                    isSelected: _selectedRelatedCategory == _currentVideo.categoryId,
                    onTap: () => setState(() {
                      _selectedRelatedCategory = _selectedRelatedCategory == _currentVideo.categoryId
                          ? null
                          : _currentVideo.categoryId;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

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
    );
  }

  // ==========================================
  // 1a. FIXED TOP BAR (COMMON HEADER FOR LANDSCAPE & PORTRAIT)
  // ==========================================
  Widget _buildFixedTopBar(
    BuildContext context, {
    required bool isLandscape,
  }) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: KidColors.canvasDark,
        border: Border(
          bottom: BorderSide(color: KidColors.borderDark, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Back / Close Button
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),

          // Video Title
          Expanded(
            child: Text(
              _cleanTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Lock Screen (Toddler Lock)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Lock Screen',
            onPressed: () => setState(() {
              _isLocked = true;
              _showControls = false;
            }),
          ),

          // Fullscreen / Landscape Switcher
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.fullscreen_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: isLandscape ? 'Full Bleed Video' : 'Landscape Fullscreen',
            onPressed: () {
              final provider = Provider.of<AppProvider>(context, listen: false);
              _orientationModeBeforeFullscreen = provider.orientationMode;
              _wasLandscapeBeforeFullscreen = isLandscape;
              if (isLandscape) {
                setState(() => _isImmersiveLandscape = true);
              } else {
                _toggleOrientation(toLandscape: true);
                setState(() => _isImmersiveLandscape = true);
              }
            },
          ),

          // Mode Selector (3-way cycle toggle)
          const OrientationModeSwitch(size: 20, color: Colors.white),
        ],
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
                      if (item.isShort || (!item.needsEmbed && item.duration > 0 && item.durationFormatted.isNotEmpty && item.durationFormatted != '0:00'))
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
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    onPressed: _exitFullscreen,
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
                    visualDensity: VisualDensity.compact,
                    icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 20),
                    onPressed: _toggleMute,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
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
                        onPressed: _exitFullscreen,
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

  String get _currentCategoryName {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final catName = provider.categories
        .where((c) => c.id == _currentVideo.categoryId)
        .firstOrNull
        ?.name;
    if (catName == null || catName.isEmpty) return 'Category';
    return catName.replaceAll(RegExp(r'^[^\w\s&]+'), '').trim();
  }

  Widget _buildRecommendationFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? KidColors.chipSelectedBg : KidColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : KidColors.borderDark,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: isSelected ? KidColors.chipSelectedText : KidColors.chipUnselectedText,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
