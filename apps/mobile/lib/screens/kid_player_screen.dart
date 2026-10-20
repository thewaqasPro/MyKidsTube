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
import '../services/infinite_video_queue.dart';
import '../utils/constants.dart';
import '../widgets/child_avatar.dart';
import '../widgets/touch_lock_overlay.dart';
import '../widgets/video_card.dart';
import '../widgets/kid_embed_player.dart';
import '../widgets/orientation_mode_switch.dart';
import '../widgets/player_suggestion_drawer.dart';
import '../widgets/kid_profile_switcher_sheet.dart';
import 'kid_shorts_feed_screen.dart';
import 'parent_gate_dialog.dart';

/// Authentic YouTube / YouTube Kids Player Screen
/// Features 100% full-screen immersive video playback, vertical swipe for infinite next/prev,
/// right-side floating action icon column, and right-side Up Next suggestions drawer.
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
  late InfiniteVideoQueue _queue;
  late PageController _pageController;
  int _currentIndex = 0;

  bool _isRightDrawerOpen = false;
  double _horizontalDragOffset = 0.0;

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLocked = false;
  bool _showControls = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isTimeUp = false;
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
  Key _embedPlayerKey = UniqueKey();
  late final GlobalKey _nativePlayerKey = GlobalKey(debugLabel: 'kid_native_player');
  // ignore: unused_field
  String? _selectedRelatedCategory;
  int _controllerGeneration = 0;
  VideoPlayerController? _inFlightController;

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
      _pageController = PageController();
      return;
    }

    _pageController = PageController(initialPage: InfiniteVideoQueue.kInitialPageIndex);

    WakelockPlus.enable();
    _startWatchTracker();
  }

  bool _queueInitialized = false;
  void _ensureQueueInitialized() {
    if (_queueInitialized) return;
    _queueInitialized = true;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final pool = (widget.playlist.isNotEmpty ? widget.playlist : provider.allVideos)
        .where((v) => !v.isShort)
        .toList();
    _queue = InfiniteVideoQueue(
      pool: pool.isNotEmpty ? pool : [widget.video],
      initialVideo: widget.video,
    );
    _currentIndex = InfiniteVideoQueue.kInitialPageIndex;
    _currentVideo = _queue.videoAt(_currentIndex);
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
    final gen = ++_controllerGeneration;

    _flushWatchSession();
    _hideControlsTimer?.cancel();
    _isAutoAdvancing = false;

    _inFlightController?.dispose();
    _inFlightController = null;

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
      _isTimeUp = false;
      _embedPlayerKey = UniqueKey();
    });

    if (shouldEmbed) {
      // In embed mode, KidEmbedPlayer automatically streams via YouTube embed
      return;
    }

    VideoPlayerController? ctrl;
    try {
      ctrl = hasLocal
          ? VideoPlayerController.file(File(video.localFilePath!))
          : VideoPlayerController.networkUrl(Uri.parse(video.streamUrl));

      _inFlightController = ctrl;

      await ctrl.initialize();

      // Bail out after await if stale — dispose the local controller, never call
      // setState/addListener/play on a controller it doesn't own
      if (!mounted || _controllerGeneration != gen) {
        if (_inFlightController == ctrl) {
          _inFlightController = null;
        }
        ctrl.dispose();
        return;
      }

      if (_inFlightController == ctrl) {
        _inFlightController = null;
      }
      _controller = ctrl;
      ctrl.addListener(_playerListener);
      ctrl.setVolume(_isMuted ? 0.0 : 1.0);
      ctrl.play();

      if (mounted && _controllerGeneration == gen) {
        setState(() {
          _isInitialized = true;
        });
        _resetControlsTimer();
      }
    } catch (e) {
      try {
        ctrl?.dispose();
      } catch (_) {}

      if (_inFlightController == ctrl) {
        _inFlightController = null;
      }

      // Bail out if stale — never flip _useEmbed for a superseded call, never show error card
      if (!mounted || _controllerGeneration != gen) {
        return;
      }

      if (video.effectiveYoutubeId.isNotEmpty && !_useEmbed) {
        if (mounted && _controllerGeneration == gen) {
          setState(() {
            _useEmbed = true;
            _hasError = false;
          });
        }
      } else {
        if (mounted && _controllerGeneration == gen) {
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
      final provider = context.read<AppProvider>();
      if (!provider.autoplayEnabled) {
        _isAutoAdvancing = true;
        _flushWatchSession(isAtVideoEnd: true);
        return;
      }
      if (provider.isAutoplaySessionLimitReached) {
        _isAutoAdvancing = true;
        _flushWatchSession(isAtVideoEnd: true);
        provider.markAutoplaySessionLimitFired();
        _controller?.pause();
        setState(() {
          _isLocked = false;
          _isTimeUp = true;
        });
        return;
      }
      _isAutoAdvancing = true;
      _flushWatchSession(isAtVideoEnd: true);
      if (_currentVideo.isShort) {
        _advanceToNextShort(isAutomatic: true);
      } else {
        _playNextVideo(isAutomatic: true);
      }
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

  void _onPageChanged(int index) {
    _flushWatchSession();
    setState(() {
      _currentIndex = index;
      _currentVideo = _queue.videoAt(index);
      _isTimeUp = false;
      _isAutoAdvancing = false;
    });

    _initControllerForVideo(_currentVideo);
  }

  void _playNextVideo({bool isAutomatic = false}) {
    final provider = context.read<AppProvider>();
    if (isAutomatic) {
      if (!provider.autoplayEnabled) return;
      if (provider.isAutoplaySessionLimitReached) {
        _flushWatchSession(isAtVideoEnd: true);
        provider.markAutoplaySessionLimitFired();
        _controller?.pause();
        setState(() {
          _isLocked = false;
          _isTimeUp = true;
        });
        return;
      }
    }

    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // ignore: unused_element
  void _playPreviousVideo() {
    if (_pageController.hasClients && _currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _jumpToVideo(int poolIndex) {
    if (_queue.pool.isEmpty) return;
    final currentPoolIdx = _queue.getPoolIndex(_currentIndex);
    int delta = poolIndex - currentPoolIdx;
    final poolLen = _queue.pool.length;
    if (delta > poolLen ~/ 2) {
      delta -= poolLen;
    } else if (delta < -poolLen ~/ 2) {
      delta += poolLen;
    }
    final targetPage = _currentIndex + delta;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _advanceToNextShort({bool isAutomatic = false}) {
    _playNextVideo(isAutomatic: isAutomatic);
  }

  void _handleEmbedEnded() {
    if (!mounted || _isAutoAdvancing) return;
    final provider = context.read<AppProvider>();
    if (!provider.autoplayEnabled) {
      _isAutoAdvancing = true;
      _flushWatchSession(isAtVideoEnd: true);
      return;
    }
    if (provider.isAutoplaySessionLimitReached) {
      _isAutoAdvancing = true;
      _flushWatchSession(isAtVideoEnd: true);
      provider.markAutoplaySessionLimitFired();
      setState(() {
        _isLocked = false;
        _isTimeUp = true;
      });
      return;
    }
    _isAutoAdvancing = true;
    _flushWatchSession(isAtVideoEnd: true);
    if (_currentVideo.isShort) {
      _advanceToNextShort();
    } else {
      _playNextVideo(isAutomatic: true);
    }
  }

  void _handleEmbedVideoChanged(String unknownId) {
    if (!mounted) return;
    if (unknownId.isEmpty || unknownId == _currentVideo.effectiveYoutubeId) return;

    // Safety guard: uncurated YouTube content attempted playback from end-screen.
    // Never allow uncurated content to play silently: pause & show the error card.
    setState(() {
      _hasError = true;
      _errorMessage = 'Uncurated video blocked for child safety.';
    });
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

  // ignore: unused_element
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
      _orientationModeBeforeFullscreen ??= provider.orientationMode;
      _isImmersiveLandscape = true;
      provider.setOrientationMode(AppOrientationMode.landscape);
    } else {
      _isImmersiveLandscape = false;
      if (_orientationModeBeforeFullscreen != null) {
        provider.setOrientationMode(_orientationModeBeforeFullscreen!);
        _orientationModeBeforeFullscreen = null;
      } else {
        provider.setOrientationMode(AppOrientationMode.portrait);
      }
    }
  }

  void _exitFullscreen() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (_orientationModeBeforeFullscreen != null) {
      provider.setOrientationMode(_orientationModeBeforeFullscreen!);
      _orientationModeBeforeFullscreen = null;
    } else {
      if (!_wasLandscapeBeforeFullscreen) {
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
    _controllerGeneration++;
    _inFlightController?.dispose();
    _inFlightController = null;
    WakelockPlus.disable();
    _hideControlsTimer?.cancel();
    _watchTrackerTimer?.cancel();
    _flushWatchSession();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    _controller = null;
    _pageController.dispose();

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

    _ensureQueueInitialized();

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
    final provider = context.watch<AppProvider>();
    _savedOrientationMode = provider.orientationMode;

    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;

    return PopScope(
      canPop: !_isLocked && !_isRightDrawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isRightDrawerOpen) {
          setState(() => _isRightDrawerOpen = false);
          return;
        }
        if (_isImmersiveLandscape && !_isLocked) {
          _exitFullscreen();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            _horizontalDragOffset = 0.0;
          },
          onHorizontalDragUpdate: (details) {
            _horizontalDragOffset += details.delta.dx;
          },
          onHorizontalDragEnd: (details) {
            if (_isLocked) return;
            final velocity = details.primaryVelocity ?? 0.0;
            if (velocity > 180 || _horizontalDragOffset > 60) {
              // Swiped right -> close right suggestion drawer if open
              if (_isRightDrawerOpen) {
                setState(() => _isRightDrawerOpen = false);
              }
            } else if (velocity < -180 || _horizontalDragOffset < -60) {
              // Swiped left -> Open right suggestion drawer
              setState(() => _isRightDrawerOpen = true);
            }
            _horizontalDragOffset = 0.0;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ==========================================
              // LAYER 1: 100% FULL-SCREEN VERTICAL SWIPE FEED
              // ==========================================
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: (_isLocked || _isRightDrawerOpen)
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: null,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    if (index == _currentIndex) {
                      return _buildPlayerSurface();
                    }
                    final video = _queue.videoAt(index);
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Center(
                            child: CircularProgressIndicator(color: KidColors.primary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Direct controls & scrubber overlay with video title at the BOTTOM
              if (!_useEmbed && _showControls && !_isLocked && !_isTimeUp)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: _buildControlsOverlay(context, position, duration, padding),
                  ),
                ),

              // Floating Action Buttons (Column in portrait, Row RTL at top in landscape)
              if (_showControls && !_isLocked && !_isRightDrawerOpen)
                Positioned(
                  right: padding.right + 12,
                  top: padding.top + (isLandscape ? 8 : 14),
                  child: isLandscape
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.rtl,
                          children: [
                            _buildActionIcon(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Exit',
                              onTap: () {
                                if (_isImmersiveLandscape) {
                                  _exitFullscreen();
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildAvatarActionIcon(provider),
                            const SizedBox(width: 10),
                            _buildActionIcon(
                              icon: Icons.stay_current_portrait_rounded,
                              tooltip: 'Switch to Portrait',
                              onTap: () {
                                _toggleOrientation(toLandscape: false);
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildActionIcon(
                              icon: Icons.lock_outline_rounded,
                              tooltip: 'Lock screen',
                              onTap: () => setState(() {
                                _isLocked = true;
                                _showControls = false;
                                _isRightDrawerOpen = false;
                              }),
                            ),
                            const SizedBox(width: 10),
                            _buildActionIcon(
                              icon: Icons.playlist_play_rounded,
                              tooltip: 'Up Next',
                              onTap: () => setState(() => _isRightDrawerOpen = true),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionIcon(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Exit',
                              onTap: () {
                                if (_isImmersiveLandscape) {
                                  _exitFullscreen();
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildAvatarActionIcon(provider),
                            const SizedBox(height: 10),
                            _buildActionIcon(
                              icon: Icons.stay_current_landscape_rounded,
                              tooltip: 'Switch to Landscape',
                              onTap: () {
                                _toggleOrientation(toLandscape: true);
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildActionIcon(
                              icon: Icons.lock_outline_rounded,
                              tooltip: 'Lock screen',
                              onTap: () => setState(() {
                                _isLocked = true;
                                _showControls = false;
                                _isRightDrawerOpen = false;
                              }),
                            ),
                            const SizedBox(height: 10),
                            _buildActionIcon(
                              icon: Icons.playlist_play_rounded,
                              tooltip: 'Up Next',
                              onTap: () => setState(() => _isRightDrawerOpen = true),
                            ),
                          ],
                        ),
                ),

              // ==========================================
              // LAYER 2: RIGHT SUGGESTION DRAWER (OVERLAY)
              // ==========================================
              PlayerSuggestionDrawer(
                isOpen: _isRightDrawerOpen,
                onClose: () => setState(() => _isRightDrawerOpen = false),
                videos: _queue.pool,
                currentIndex: _queue.getPoolIndex(_currentIndex),
                onSelectVideo: (idx) {
                  setState(() => _isRightDrawerOpen = false);
                  _jumpToVideo(idx);
                },
                onShuffle: () {
                  setState(() {
                    _queue.shufflePool(currentVirtualIndex: _currentIndex);
                  });
                },
              ),

              // ==========================================
              // LAYER 3: TOUCH LOCK OVERLAY
              // ==========================================
              TouchLockOverlay(
                isLocked: _isLocked,
                showLockButton: false,
                onLock: () => setState(() {
                  _isLocked = true;
                  _showControls = false;
                  _isRightDrawerOpen = false;
                }),
                onUnlock: () => setState(() {
                  _isLocked = false;
                  _showControls = true;
                }),
              ),

              // ==========================================
              // LAYER 4: TIME'S UP OVERLAY (SESSION LIMIT)
              // ==========================================
              if (_isTimeUp)
                Positioned.fill(
                  child: _buildTimeUpOverlay(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 21),
        ),
      ),
    );
  }

  Widget _buildAvatarActionIcon(AppProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => KidProfileSwitcherSheet.show(context),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: ChildAvatar(
              avatarIcon: provider.activeProfile?.avatarIcon ?? 'bear',
              radius: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(
    BuildContext context,
    Duration position,
    Duration duration,
    EdgeInsets padding,
  ) {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: SafeArea(
        child: Stack(
          children: [
            // Center Play/Pause & Skip buttons
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 32),
                    tooltip: 'Replay 10s',
                    onPressed: () => _seekRelative(-10),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1.2),
                      ),
                      child: Icon(
                        _controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 32),
                    tooltip: 'Forward 10s',
                    onPressed: () => _seekRelative(10),
                  ),
                ],
              ),
            ),

            // Bottom Video Title, Red Scrubber Bar & Timestamps (No quality badges)
            Positioned(
              left: 14,
              right: 14,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title positioned at the BOTTOM
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 60, bottom: 4),
                    child: Text(
                      _cleanTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                  _buildRedScrubber(position, duration),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Toddler Lock quick button
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 18),
                              tooltip: 'Lock screen',
                              onPressed: () => setState(() {
                                _isLocked = true;
                                _showControls = false;
                              }),
                            ),
                            // Orientation toggle button
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                MediaQuery.of(context).orientation == Orientation.landscape
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              tooltip: MediaQuery.of(context).orientation == Orientation.landscape
                                  ? 'Exit Fullscreen'
                                  : 'Fullscreen',
                              onPressed: () {
                                final isLand = MediaQuery.of(context).orientation == Orientation.landscape;
                                _toggleOrientation(toLandscape: !isLand);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUpOverlay() {
    return Container(
      color: const Color(0xF20D1A33),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: KidColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KidColors.yellow.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KidColors.yellow.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: KidColors.yellow.withValues(alpha: 0.6), width: 2),
                    ),
                    child: const Icon(
                      Icons.timer_off_rounded,
                      color: KidColors.yellow,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Time's up",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "You've reached your watch limit for this session. A grown-up can enter their PIN or solve the challenge to continue.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white70,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: KidColors.borderDark),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          if (_isImmersiveLandscape) {
                            _exitFullscreen();
                          }
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KidColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _handleContinueFromTimeUp,
                        icon: const Icon(Icons.lock_open_rounded, size: 18),
                        label: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinueFromTimeUp() async {
    final passed = await ParentGateDialog.showChallenge(context);
    if (!passed || !mounted) return;

    final provider = context.read<AppProvider>();
    provider.extendOrResetAutoplaySession();

    setState(() {
      _isTimeUp = false;
      _isAutoAdvancing = false;
    });

    _playNextVideo();
  }

  Widget _buildPlayerSurface() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: _useEmbed
                ? (_hasError
                    ? _buildPendingOrErrorState()
                    : KidEmbedPlayer(
                        key: _embedPlayerKey,
                        youtubeId: _currentVideo.effectiveYoutubeId,
                        autoPlay: true,
                        isMuted: _isMuted,
                        scale: 1.14,
                        onEnded: _handleEmbedEnded,
                        onVideoChanged: _handleEmbedVideoChanged,
                        onUnknownVideoDetected: _handleEmbedVideoChanged,
                      ))
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
          if (!_isLocked && !_useEmbed && !_hasError)
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

  // ignore: unused_element
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

  // ignore: unused_element
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
                final provider = Provider.of<AppProvider>(context, listen: false);
                _orientationModeBeforeFullscreen = provider.orientationMode;
                _wasLandscapeBeforeFullscreen = false;
                _toggleOrientation(toLandscape: true);
                setState(() => _isImmersiveLandscape = true);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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
          if (!_useEmbed) ...[
            Text(
              '${_formatDuration(position)} / ${_formatDuration(duration)}${_currentVideo.fileSizeBytes > 0 ? " • ${(_currentVideo.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB" : ""}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: KidColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
          ],
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

  // ignore: unused_element
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
          const OrientationModeSwitch(size: 20, color: Colors.white),
        ],
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
                  child: Icon(
                    _errorMessage.isNotEmpty ? Icons.security_rounded : Icons.cloud_sync_rounded,
                    color: KidColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage.isNotEmpty ? 'Playback Blocked' : 'Video Queued for Sync',
                  style: const TextStyle(
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
                const SizedBox(height: 14),
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
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        _errorMessage.isNotEmpty ? 'Reload Video' : 'Play via Embed',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
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

  Widget _buildRedScrubber(Duration position, Duration duration) {
    final maxMs = duration.inMilliseconds.toDouble();
    final currentMs = position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: KidColors.primary,
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
}
