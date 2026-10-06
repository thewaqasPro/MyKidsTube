import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class TouchLockOverlay extends StatefulWidget {
  final bool isLocked;
  final VoidCallback onUnlock;
  final VoidCallback onLock;
  final bool showLockButton;

  const TouchLockOverlay({
    super.key,
    required this.isLocked,
    required this.onUnlock,
    required this.onLock,
    this.showLockButton = true,
  });

  @override
  State<TouchLockOverlay> createState() => _TouchLockOverlayState();
}

class _TouchLockOverlayState extends State<TouchLockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onUnlock();
        _progressController.reset();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _onHoldStart() {
    HapticFeedback.lightImpact();
    _progressController.forward();
  }

  void _onHoldEnd() {
    if (_progressController.status != AnimationStatus.completed) {
      _progressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLocked) {
      if (!widget.showLockButton) return const SizedBox.shrink();
      // Small button to lock
      return Positioned(
        top: 24,
        right: 24,
        child: GestureDetector(
          onTap: widget.onLock,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_open_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Lock Screen',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // When locked: screen is shielded, hold-to-unlock button is prominent
    return Stack(
      children: [
        // Touch blocker
        AbsorbPointer(
          absorbing: true,
          child: Container(color: Colors.transparent),
        ),

        // Unlocking interactive widget
        Positioned(
          top: 24,
          right: 24,
          child: GestureDetector(
            onTapDown: (_) => _onHoldStart(),
            onTapUp: (_) => _onHoldEnd(),
            onTapCancel: () => _onHoldEnd(),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: KidColors.accent, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _progressController.value,
                              strokeWidth: 3,
                              color: KidColors.accent,
                              backgroundColor: Colors.white24,
                            ),
                            const Icon(Icons.lock_rounded, color: Colors.white, size: 13),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _progressController.value > 0 ? 'Hold 3s to Unlock...' : 'Hold to Unlock',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
