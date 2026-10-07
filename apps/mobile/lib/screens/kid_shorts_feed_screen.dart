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
import '../widgets/ambient_blur_background.dart';
import '../widgets/kid_embed_player.dart';
import '../widgets/shorts_action_rail.dart';
import '../widgets/touch_lock_overlay.dart';
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
  bool _isMuted = false;
  bool _autoAdvance = true;

  bool _showPlayPauseIcon = false;
  bool _lastActionWasPlay = true;
  Timer? _playPauseTimer;

  @override
  void initState() {
    super.initState();
    // Strictly isolate short videos (<= 70s / vertical)
    final filtered = widget.videos.where((v) => v.isShort).toList();
    _shorts = filtered.isNotEmpty ? filtered : widget.videos;

    final initialVideo = (widget.initialIndex >= 0 && widget.initialIndex < widget.videos.length)
        ? widget.videos[widget.initialIndex]
        : null;
    int targetIndex = 0;
    if (initialVideo != null) {
      final found = _shorts.indexWhere((v) => v.id == initialVideo.id);
      if (found != -1) targetIndex = found;
    }
    _currentIndex = targetIndex.clamp(0, _shorts.isEmpty ? 0 : _shorts.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WakelockPlus.enable();

    _initControllersForWindow(_currentIndex);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _playPauseTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _controllerGeneration.clear();
    _pageController.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

    if (_autoAdvance && _currentIndex < _shorts.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Loop video
      final ctrl = _controllers[index];
      ctrl?.seekTo(Duration.zero);
      ctrl?.play();
    }
  }

  void _onPageChanged(int newIndex) {
    // Pause previous
    final prevCtrl = _controllers[_currentIndex];
    prevCtrl?.pause();

    setState(() {
      _currentIndex = newIndex;
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

  void _toggleFavorite() {
    final video = _shorts[_currentIndex];
    context.read<AppProvider>().toggleFavorite(video.id);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      for (final ctrl in _controllers.values) {
        ctrl.setVolume(_isMuted ? 0.0 : 1.0);
      }
    });
  }

  void _toggleAutoAdvance() {
    setState(() {
      _autoAdvance = !_autoAdvance;
    });
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
              physics: _isLocked ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPage(int index) {
    final video = _shorts[index];
    final ctrl = _controllers[index];
    final isInitialized = ctrl != null && ctrl.value.isInitialized;
    final isInitializing = ctrl != null && !ctrl.value.isInitialized;
    final isFavorite = context.watch<AppProvider>().isFavorite(video.id);
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
      onDoubleTap: _toggleFavorite,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A. Ambient Background for landscape videos
          AmbientBlurBackground(controller: ctrl),

          // B. Main Video Player (Centered with native aspect ratio or full 9:16)
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
                    ? AspectRatio(
                        aspectRatio: 9 / 16,
                        child: KidEmbedPlayer(
                          youtubeId: video.effectiveYoutubeId,
                          autoPlay: isCurrent,
                          aspectRatio: 9 / 16,
                        ),
                      )
                    : (_failedIndices.contains(index)
                        ? _buildShortPendingState(video)
                        : (isInitializing
                            ? const Center(
                                child: CircularProgressIndicator(color: KidColors.primary),
                              )
                            : (video.thumbnailUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: video.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Center(
                                      child: CircularProgressIndicator(color: KidColors.primary),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(color: KidColors.primary),
                                  ))))),
          ),

          // C. Top Navigation Bar (Back + Parent Shield)
          if (!_isLocked)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, color: KidColors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${index + 1} / ${_shorts.length}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Parent Gate
                  GestureDetector(
                    onTap: () => ParentGateDialog.show(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

          // D. Right Floating Action Rail
          Positioned(
            right: 14,
            bottom: 85,
            child: ShortsActionRail(
              isFavorite: isFavorite,
              isLocked: _isLocked,
              isMuted: _isMuted,
              autoAdvance: _autoAdvance,
              onToggleFavorite: _toggleFavorite,
              onToggleMute: _toggleMute,
              onToggleAutoAdvance: _toggleAutoAdvance,
              onExit: () => Navigator.of(context).pop(),
              onLockTap: () => setState(() => _isLocked = true),
              onNextShort: _goToNextShort,
            ),
          ),

          // E. Bottom Video Meta Info & Scrub Bar
          if (!_isLocked)
            Positioned(
              left: 16,
              right: 80, // leaves room for action rail
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
          CachedNetworkImage(
            imageUrl: video.thumbnailUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: const Color(0xFF18181B)),
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
                  label: const Text('Next Short ⚡', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
