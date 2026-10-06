import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ShortsActionRail extends StatelessWidget {
  final bool isFavorite;
  final bool isLocked;
  final bool isMuted;
  final bool autoAdvance;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleAutoAdvance;
  final VoidCallback onExit;
  final VoidCallback onLockTap;

  const ShortsActionRail({
    super.key,
    required this.isFavorite,
    required this.isLocked,
    required this.isMuted,
    required this.autoAdvance,
    required this.onToggleFavorite,
    required this.onToggleMute,
    required this.onToggleAutoAdvance,
    required this.onExit,
    required this.onLockTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Favorite Star Button
        _buildRailButton(
          icon: isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFavorite ? KidColors.yellow : Colors.white,
          label: isFavorite ? 'Starred' : 'Favorite',
          onTap: onToggleFavorite,
        ),
        const SizedBox(height: 18),

        // 2. Sound Toggle
        _buildRailButton(
          icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: isMuted ? KidColors.red : Colors.white,
          label: isMuted ? 'Muted' : 'Sound',
          onTap: onToggleMute,
        ),
        const SizedBox(height: 18),

        // 3. Auto-Advance vs Loop Toggle
        _buildRailButton(
          icon: autoAdvance ? Icons.queue_play_next_rounded : Icons.repeat_one_rounded,
          color: autoAdvance ? KidColors.primary : KidColors.accent,
          label: autoAdvance ? 'Auto Next' : 'Loop',
          onTap: onToggleAutoAdvance,
        ),
        const SizedBox(height: 18),

        // 4. Toddler Lock Indicator / Button
        _buildRailButton(
          icon: Icons.lock_outline_rounded,
          color: Colors.white,
          label: 'Lock',
          onTap: onLockTap,
        ),
      ],
    );
  }

  Widget _buildRailButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.0),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
