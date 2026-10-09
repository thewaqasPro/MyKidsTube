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
import '../widgets/child_avatar.dart';
import '../widgets/kid_embed_player.dart';
import '../widgets/kid_profile_switcher_sheet.dart';
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
  late List<VideoItem> _shorts;
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, int> _controllerGeneration = {};
  final Set<int> _failedIndices = {};

  bool _isLocked = false;
  final bool _isMuted = false;
  bool _isTimeUp = false;

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
      _shorts = [];
      _pageController = PageController();
      return;
    }

    // Strictly isolate short videos (vertical format, <= 70s, /shorts/ URL)
    final filtered = widget.videos.where((v) => v.isShort).toList();
    _shorts = filtered;

    if (_shorts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      _pageController = PageController();
      return;
    }

    int targetIndex = 0;
    if (initialVideo != null) {
      final found = _shorts.indexWhere((v) => v.id == initialVideo.id);
      if (found != -1) targetIndex = found;
    }
    _currentIndex = targetIndex.clamp(0, _shorts.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

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
    if (_accumulatedSessionSeconds > 0 && _currentIndex >= 0 && _currentIndex < _shorts.length) {
      final currentVideo = _shorts[_currentIndex];
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

  AppOrientationMode _savedOrientationMode = AppOrientationMode.auto;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _savedOrientationMode = provider.orientationMode;
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _playPauseTimer?.cancel();
    _watchTrackerTimer?.cancel();
    _flushWatchSession();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _controllerGeneration.clear();
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
      if (idx >= 0 && idx < _shorts.length && !_controllers.containsKey(idx)) {
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
    if (index < 0 || index >= _shorts.length) return;
    final video = _shorts[index];

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

    _controllers[index] = ctrl;

    ctrl.initialize().then((_) {
      if (!mounted || _controllerGeneration[index] != gen || !_controllers.containsKey(index)) {
        return;
      }
      ctrl.setVolume(_isMuted ? 0.0 : 1.0);

      // Listener for video completion / auto advance
      ctrl.addListener(() {
        if (!mounted || _controllerGeneration[index] != gen) return;
        if (ctrl.value.isInitialized &&
            ctrl.value.position >= ctrl.value.duration &&
            ctrl.value.duration > Duration.zero) {
          _onVideoFinished(index);
        }
      });

      if (autoPlay && index == _currentIndex) {
        ctrl.play();
      }
      setState(() {});
    }).catchError((err) {
      if (!mounted || _controllerGeneration[index] != gen) return;
      setState(() {
        _failedIndices.add(index);
      });
    });
  }

  void _goToNextShort() {
    if (_currentIndex < _shorts.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onVideoFinished(int index) {
    if (index != _currentIndex) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    if (!provider.autoplayEnabled) {
      // Autoplay off: zero automatic advancement (native + embed, shorts + player)
      _flushWatchSession(isAtVideoEnd: true);
      final ctrl = _controllers[index];
      ctrl?.pause();
      return;
    }

    if (provider.isAutoplaySessionLimitReached) {
      // Session limit reached: stop at end of current video, show "Time's up" card
      _flushWatchSession(isAtVideoEnd: true);
      provider.markAutoplaySessionLimitFired();
      final ctrl = _controllers[index];
      ctrl?.pause();
      setState(() {
        _isLocked = false;
        _isTimeUp = true;
      });
      return;
    }

    if (_currentIndex < _shorts.length - 1) {
      _flushWatchSession(isAtVideoEnd: true);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Loop video
      _flushWatchSession(isAtVideoEnd: true);
      final ctrl = _controllers[index];
      ctrl?.seekTo(Duration.zero);
      ctrl?.play();
    }
  }

  void _onPageChanged(int newIndex) {
    _flushWatchSession();
    // Pause previous
    final prevCtrl = _controllers[_currentIndex];
    prevCtrl?.pause();

    setState(() {
      _currentIndex = newIndex;
      _isTimeUp = false;
    });

    _initControllersForWindow(newIndex);
  }

  void _togglePlayPause() {
    if (_isLocked) return;

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
    _playPauseTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showPlayPauseIcon = false);
    });
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEB0D1A33),
        border: const Border(
          bottom: BorderSide(color: KidColors.borderDark, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // 1. Back button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),

                // 2. Shorts Title
                const Text(
                  'Shorts',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),

                const Spacer(),

                // 3. Toddler Lock
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Lock Screen',
                  onPressed: () => setState(() => _isLocked = true),
                ),

                // 4. Active Child Avatar
                Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: GestureDetector(
                    onTap: () => KidProfileSwitcherSheet.show(context),
                    child: ChildAvatar(
                      avatarIcon: context.watch<AppProvider>().activeProfile?.avatarIcon,
                      radius: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shorts.isEmpty) {
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

    return PopScope(
      canPop: !_isLocked,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Vertical Fullscreen PageView
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: (_isLocked || _isTimeUp) ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              itemCount: _shorts.length,
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

            // 3. Toddler Touch Lock Overlay
            TouchLockOverlay(
              isLocked: _isLocked,
              showLockButton: false,
              onLock: () => setState(() => _isLocked = true),
              onUnlock: () => setState(() => _isLocked = false),
            ),

            // 4. Fixed Blue Top Bar (Visible & Stable across Shorts transitions)
            if (!_isLocked)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(context),
              ),

            // 5. Time's Up Overlay (Session Limit)
            if (_isTimeUp)
              Positioned.fill(
                child: _buildTimeUpOverlay(),
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
    final video = _shorts[index];
    final ctrl = _controllers[index];
    final isInitialized = ctrl != null && ctrl.value.isInitialized;
    final isInitializing = ctrl != null && !ctrl.value.isInitialized;
    final isCurrent = index == _currentIndex;

    // Only activate embed when on current visible index, not initializing, and video genuinely needs embed
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
          // A. Clean Solid Black Backdrop (No Gaussian blur on transitions!)
          Container(color: Colors.black),

          // B. Main Video Player (Centered or Edge-to-Edge)
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

          // C. Bottom Video Meta Info & Scrub Bar (Full Width, No Side Rail)
          if (!_isLocked)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Channel Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KidColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      video.title.contains('•') ? video.title.split('•').first.trim() : 'Kids Shorts',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    video.title.contains('•') ? video.title.split('•').last.trim() : video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Scrub Progress Bar
                  if (isInitialized)
                    VideoProgressIndicator(
                      ctrl,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      colors: const VideoProgressColors(
                        playedColor: KidColors.primary,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShortPendingState(VideoItem video) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (video.thumbnailUrl.isNotEmpty)
          FittedBox(
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
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF18181B)),
                ),
              ),
            ),
          ),
        Container(
          color: Colors.black.withValues(alpha: 0.65),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KidColors.yellow.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: KidColors.yellow, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Short Syncing to Storage',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap anywhere or swipe up for next short',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KidColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: _goToNextShort,
                  icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                  label: const Text('Next Short', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
