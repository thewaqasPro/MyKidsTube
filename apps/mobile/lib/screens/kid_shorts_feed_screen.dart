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
import '../widgets/kid_embed_player.dart';
import '../widgets/kid_profile_switcher_sheet.dart';
import '../widgets/player_suggestion_drawer.dart';
import '../widgets/touch_lock_overlay.dart';
import 'kid_player_screen.dart';
import 'parent_gate_dialog.dart';

class KidShortsFeedScreen extends StatefulWidget {
  final List<VideoItem> videos;
  final int initialIndex;

  const KidShortsFeedScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  @override
  State<KidShortsFeedScreen> createState() => _KidShortsFeedScreenState();
}

class _KidShortsFeedScreenState extends State<KidShortsFeedScreen> with TickerProviderStateMixin {
  late InfiniteVideoQueue _queue;
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, int> _controllerGeneration = {};
  final Set<int> _failedIndices = {};

  bool _isLocked = false;
  bool _isMuted = false;
  bool _isTimeUp = false;

  bool _isRightDrawerOpen = false;

  AppOrientationMode _savedOrientationMode = AppOrientationMode.auto;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _savedOrientationMode = provider.orientationMode;
  }

  bool _showPlayPauseIcon = false;
  bool _lastActionWasPlay = true;
  Timer? _playPauseTimer;
  Timer? _watchTrackerTimer;
  int _accumulatedSessionSeconds = 0;

  @override
  void initState() {
    super.initState();
    final initialVideo = (widget.initialIndex >= 0 && widget.initialIndex < widget.videos.length)
        ? widget.videos[widget.initialIndex]
        : null;

    // Safety guard: If initial video is landscape, redirect to standard watch player!
    if (initialVideo != null && !initialVideo.isShort) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => KidPlayerScreen(
                video: initialVideo,
                playlist: widget.videos.where((v) => !v.isShort).toList(),
              ),
            ),
          );
        }
      });
      _pageController = PageController();
      return;
    }

    // Strictly isolate short videos (vertical format, <= 70s, /shorts/ URL)
    final filtered = widget.videos.where((v) => v.isShort).toList();

    if (filtered.isEmpty && initialVideo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      _pageController = PageController();
      return;
    }

    _queue = InfiniteVideoQueue(
      pool: filtered.isNotEmpty ? filtered : [if (initialVideo != null) initialVideo],
      initialVideo: initialVideo,
    );

    _currentIndex = 0;
    _pageController = PageController(initialPage: 0);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WakelockPlus.enable();

    _startWatchTracker();
    _initControllersForWindow(_currentIndex);
  }

  void _startWatchTracker() {
    _watchTrackerTimer?.cancel();
    _watchTrackerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final ctrl = _controllers[_currentIndex];
      final isPlaying = ctrl != null && ctrl.value.isInitialized && ctrl.value.isPlaying;
      if (isPlaying) {
        _accumulatedSessionSeconds += 1;
        if (_accumulatedSessionSeconds >= 300) {
          _flushWatchSession();
        }
      }
    });
  }

  void _flushWatchSession({bool isAtVideoEnd = false}) {
    if (_accumulatedSessionSeconds > 0 && _currentIndex >= 0 && _currentIndex < _queue.length) {
      final currentVideo = _queue[_currentIndex];
      final secs = _accumulatedSessionSeconds;
      _accumulatedSessionSeconds = 0;
      final duration = currentVideo.duration;
      final isSkipped = secs < 10;
      final isCompleted = isAtVideoEnd || (duration > 0 && secs >= (duration * 0.75).round());
      try {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.recordWatchSession(
          videoId: currentVideo.id,
          videoTitle: currentVideo.title,
          categoryId: currentVideo.categoryId,
          secondsWatched: secs,
          videoDuration: duration,
          isCompleted: isCompleted,
          isSkipped: isSkipped,
        );
      } catch (_) {}
    }
  }

  // ignore: unused_element
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      for (final ctrl in _controllers.values) {
        ctrl.setVolume(_isMuted ? 0.0 : 1.0);
      }
    });
  }

  void _togglePlayPause() {
    final ctrl = _controllers[_currentIndex];
    if (ctrl == null || !ctrl.value.isInitialized) return;

    setState(() {
      if (ctrl.value.isPlaying) {
        ctrl.pause();
        _lastActionWasPlay = false;
      } else {
        ctrl.play();
        _lastActionWasPlay = true;
      }
      _showPlayPauseIcon = true;
    });

    _playPauseTimer?.cancel();
    _playPauseTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _showPlayPauseIcon = false);
      }
    });
  }

  void _onPageChanged(int index) {
    _flushWatchSession();
    setState(() {
      _currentIndex = index;
    });
    _queue.ensureCapacity(index);
    _initControllersForWindow(index);
  }

  void _onVideoFinished(int index) {
    if (!mounted) return;
    _flushWatchSession(isAtVideoEnd: true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.autoplayEnabled) {
      final ctrl = _controllers[index];
      ctrl?.pause();
      return;
    }

    if (provider.isAutoplaySessionLimitReached) {
      provider.markAutoplaySessionLimitFired();
      final ctrl = _controllers[index];
      ctrl?.pause();
      setState(() {
        _isLocked = false;
        _isTimeUp = true;
      });
      return;
    }

    _goToNextShort();
  }

  void _goToNextShort() {
    if (_pageController.hasClients && _currentIndex < _queue.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _watchTrackerTimer?.cancel();
    _playPauseTimer?.cancel();
    _flushWatchSession();

    WakelockPlus.disable();
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _controllers.clear();
    _pageController.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.applyCurrentOrientationMode();
    } catch (_) {}
    super.dispose();
  }

  void _initControllersForWindow(int centerIndex) {
    final neededIndices = {centerIndex - 1, centerIndex, centerIndex + 1};

    // Dispose controllers outside window to keep memory strictly under 60MB
    final keysToRemove = <int>[];
    _controllers.forEach((idx, ctrl) {
      if (!neededIndices.contains(idx)) {
        _controllerGeneration[idx] = (_controllerGeneration[idx] ?? 0) + 1;
        ctrl.dispose();
        keysToRemove.add(idx);
      }
    });
    for (final k in keysToRemove) {
      _controllers.remove(k);
    }

    // Initialize needed controllers
    for (final idx in neededIndices) {
      if (idx >= 0 && idx < _queue.length && !_controllers.containsKey(idx)) {
        _createController(idx, autoPlay: idx == centerIndex);
      }
    }

    // Play center video
    final centerCtrl = _controllers[centerIndex];
    if (centerCtrl != null && centerCtrl.value.isInitialized) {
      centerCtrl.play();
      centerCtrl.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  void _createController(int index, {bool autoPlay = false}) {
    if (index < 0 || index >= _queue.length) return;
    final video = _queue[index];

    final hasLocal = video.localFilePath != null && File(video.localFilePath!).existsSync();
    // If video needs embed and has no local file, skip native controller
    if (!hasLocal && video.needsEmbed) {
      return;
    }

    final gen = (_controllerGeneration[index] ?? 0) + 1;
    _controllerGeneration[index] = gen;

    VideoPlayerController ctrl;
    if (hasLocal) {
      ctrl = VideoPlayerController.file(File(video.localFilePath!));
    } else {
      ctrl = VideoPlayerController.networkUrl(Uri.parse(video.streamUrl));
    }

    ctrl.initialize().then((_) {
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      if (_controllerGeneration[index] != gen) {
        ctrl.dispose();
        return;
      }

      _controllers[index] = ctrl;
      _failedIndices.remove(index);
      ctrl.setLooping(false);
      ctrl.setVolume(_isMuted ? 0.0 : 1.0);

      ctrl.addListener(() {
        if (!mounted) return;
        final val = ctrl.value;
        if (val.isInitialized &&
            !val.isPlaying &&
            val.position >= (val.duration - const Duration(milliseconds: 600)) &&
            val.duration > const Duration(seconds: 3)) {
          _onVideoFinished(index);
        }
      });

      if (autoPlay && index == _currentIndex) {
        ctrl.play();
      }

      setState(() {});
    }).catchError((_) {
      if (!mounted) return;
      if (_controllerGeneration[index] == gen) {
        ctrl.dispose();
        _controllers.remove(index);
        setState(() {
          _failedIndices.add(index);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return PopScope(
        canPop: !_isLocked,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.movie_filter_rounded, color: KidColors.textMuted, size: 54),
                const SizedBox(height: 16),
                const Text('No videos in this feed', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Home'),
                )
              ],
            ),
          ),
        ),
      );
    }

    final provider = context.watch<AppProvider>();

    return PopScope(
      canPop: !_isLocked && !_isRightDrawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isRightDrawerOpen) {
          setState(() => _isRightDrawerOpen = false);
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            if (_isLocked) return;
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -260) {
              // Swipe left -> open right suggestions drawer
              setState(() => _isRightDrawerOpen = true);
            } else if (velocity > 260) {
              // Swipe right -> close right suggestions drawer
              if (_isRightDrawerOpen) {
                setState(() => _isRightDrawerOpen = false);
              }
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Vertical Fullscreen PageView
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: (_isLocked || _isTimeUp || _isRightDrawerOpen)
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: _queue.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _buildVideoPage(index);
                },
              ),

              // 2. Play/Pause Big Center Indicator
              if (_showPlayPauseIcon)
                Center(
                  child: AnimatedOpacity(
                    opacity: _showPlayPauseIcon ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _lastActionWasPlay ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),

              // 3. Right Floating Action Column (All controls placed on right side as circular icons)
              if (!_isLocked && !_isRightDrawerOpen)
                Positioned(
                  right: 12,
                  top: MediaQuery.of(context).padding.top + 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionIcon(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Exit',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 10),
                      _buildAvatarActionIcon(provider),
                      const SizedBox(height: 10),

                      _buildActionIcon(
                        icon: Icons.lock_outline_rounded,
                        tooltip: 'Lock screen',
                        onTap: () => setState(() => _isLocked = true),
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

              // 4. Right Suggestion Drawer (Overlay)
              PlayerSuggestionDrawer(
                isOpen: _isRightDrawerOpen,
                onClose: () => setState(() => _isRightDrawerOpen = false),
                videos: _queue.items,
                currentIndex: _currentIndex,
                onSelectVideo: (idx) {
                  setState(() => _isRightDrawerOpen = false);
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubic,
                    );
                  }
                },
                onShuffle: () {
                  setState(() {
                    _queue.shuffleUpcoming(_currentIndex);
                  });
                },
              ),

              // 5. Toddler Touch Lock Overlay
              TouchLockOverlay(
                isLocked: _isLocked,
                showLockButton: false,
                onLock: () => setState(() => _isLocked = true),
                onUnlock: () => setState(() => _isLocked = false),
              ),

              // 6. Time's Up Overlay (Session Limit)
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
                        onPressed: () => Navigator.of(context).pop(),
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

    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.extendOrResetAutoplaySession();

    setState(() {
      _isTimeUp = false;
    });

    _goToNextShort();
  }

  Widget _buildVideoPage(int index) {
    final video = _queue[index];
    final ctrl = _controllers[index];
    final isInitialized = ctrl != null && ctrl.value.isInitialized;
    final isInitializing = ctrl != null && !ctrl.value.isInitialized;
    final isCurrent = index == _currentIndex;

    final isEmbed = isCurrent && !isInitializing && (video.needsEmbed || _failedIndices.contains(index));

    return GestureDetector(
      behavior: isEmbed ? HitTestBehavior.deferToChild : HitTestBehavior.opaque,
      onTap: () {
        if (!isEmbed) {
          if (_failedIndices.contains(index)) {
            _goToNextShort();
          } else {
            _togglePlayPause();
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),

          Center(
            child: isInitialized
                ? AspectRatio(
                    aspectRatio: ctrl.value.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(ctrl.value.aspectRatio > 1.2 ? 16 : 0),
                      child: VideoPlayer(ctrl),
                    ),
                  )
                : (isEmbed
                    ? Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 40,
                        ),
                        child: KidEmbedPlayer(
                          youtubeId: video.effectiveYoutubeId,
                          autoPlay: isCurrent,
                          isMuted: _isMuted,
                          scale: 1.14,
                          topShieldHeight: 68.0,
                          bottomShieldHeight: 74.0,
                          shieldColor: const Color(0xFF0D1A33),
                          onEnded: () => _onVideoFinished(index),
                          onVideoChanged: (newId) {
                            if (newId != video.effectiveYoutubeId) {
                              _onVideoFinished(index);
                            }
                          },
                          onUnknownVideoDetected: (newId) {
                            if (newId != video.effectiveYoutubeId) {
                              _onVideoFinished(index);
                            }
                          },
                        ),
                      )
                    : (_failedIndices.contains(index)
                        ? _buildShortPendingState(video)
                        : (isInitializing
                            ? const Center(
                                child: CircularProgressIndicator(color: KidColors.primary),
                              )
                            : (video.thumbnailUrl.isNotEmpty
                                ? SizedBox.expand(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      clipBehavior: Clip.hardEdge,
                                      child: SizedBox(
                                        width: 9,
                                        height: 16,
                                        child: Transform.scale(
                                          scale: 1.78,
                                          child: CachedNetworkImage(
                                            imageUrl: video.thumbnailUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Container(color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(color: KidColors.primary),
                                  ))))),
          ),

          // Shorts have NO title text overlay (kids don't read titles; pure visual screenshot view)
          // Only slim progress bar at the bottom when playing
          if (!_isLocked && isInitialized)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: VideoProgressIndicator(
                ctrl,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                colors: const VideoProgressColors(
                  playedColor: KidColors.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShortPendingState(VideoItem video) {
    return Container(
      color: const Color(0xEB0D1A33),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_sync_rounded, color: KidColors.yellow, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Short Syncing',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'This vertical video is preparing for playback.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _goToNextShort,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Next Short'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
