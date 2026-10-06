import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/video_item.dart';
import '../utils/constants.dart';
import '../widgets/touch_lock_overlay.dart';

class KidPlayerScreen extends StatefulWidget {
  final VideoItem video;

  const KidPlayerScreen({super.key, required this.video});

  @override
  State<KidPlayerScreen> createState() => _KidPlayerScreenState();
}

class _KidPlayerScreenState extends State<KidPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLocked = false;
  bool _showControls = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Allow landscape and portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final hasLocal = widget.video.localFilePath != null &&
          File(widget.video.localFilePath!).existsSync();

      if (hasLocal) {
        _controller = VideoPlayerController.file(File(widget.video.localFilePath!));
      } else {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.streamUrl));
      }

      await _controller.initialize();
      _controller.addListener(_playerListener);
      _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not load video. Please check VPS connection or file.';
        });
      }
    }
  }

  void _playerListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_playerListener);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    if (!_isLocked) {
      setState(() => _showControls = !_showControls);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLocked,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screen is locked. Hold the lock button for 3 seconds to unlock.'),
              duration: Duration(seconds: 2),
              backgroundColor: KidColors.accent,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Video Player Surface
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: KidColors.red, size: 54),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to Videos'),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: KidColors.primary),
              ),

            // 2. Gesture detector to toggle controls
            if (_isInitialized && !_isLocked)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControls,
                ),
              ),

            // 3. Child-safe controls overlay
            if (_isInitialized && !_isLocked && _showControls)
              _buildControlsOverlay(),

            // 4. Video Ended screen (Play again button)
            if (_isInitialized &&
                _controller.value.position >= _controller.value.duration &&
                _controller.value.duration.inSeconds > 0)
              _buildVideoEndedOverlay(),

            // 5. Touch Lock Overlay (Handles freeze and 3-second hold to unlock)
            TouchLockOverlay(
              isLocked: _isLocked,
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

  Widget _buildControlsOverlay() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Container(
      color: Colors.black.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar: Back button + Title
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 140), // Spacer for lock button
              ],
            ),
          ),

          // Center: Large Play/Pause button
          Center(
            child: GestureDetector(
              onTap: () {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),

          // Bottom: Kid scrubber + Timestamps
          SafeArea(
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbColor: KidColors.accent,
                    activeTrackColor: KidColors.accent,
                    inactiveTrackColor: Colors.white24,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                    min: 0,
                    max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (val) {
                      _controller.seekTo(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoEndedOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: KidColors.yellow, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Great Job Watching!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KidColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    _controller.seekTo(Duration.zero);
                    _controller.play();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 22),
                  label: const Text('Watch Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Pick Another', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
