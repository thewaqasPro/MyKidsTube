import 'package:flutter/material.dart';
import '../models/video_item.dart';
import '../utils/constants.dart';
import 'child_avatar.dart';
import 'orientation_mode_switch.dart';

/// Left-side collapsible drawer containing playback controls, lock, orientation, and navigation.
class PlayerControlDrawer extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VideoItem video;
  final VoidCallback onLock;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final String? childAvatarIcon;
  final VoidCallback? onAvatarTap;
  final bool isShort;

  const PlayerControlDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onBack,
    required this.video,
    required this.onLock,
    required this.isMuted,
    required this.onToggleMute,
    this.childAvatarIcon,
    this.onAvatarTap,
    this.isShort = false,
  });

  String get _cleanTitle {
    if (video.title.contains('•')) {
      return video.title.split('•').last.trim();
    }
    return video.title;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final drawerWidth = (mediaQuery.size.width * 0.72).clamp(240.0, 310.0);

    return IgnorePointer(
      ignoring: !isOpen,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: isOpen ? 1.0 : 0.0,
        child: Stack(
          children: [
            // Dark dismiss barrier
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),

            // Left drawer panel
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: isOpen ? 0 : -drawerWidth,
              top: 0,
              bottom: 0,
              width: drawerWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xF5111726),
                  border: const Border(
                    right: BorderSide(color: KidColors.borderDark, width: 1.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 24,
                      offset: const Offset(8, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top bar inside drawer: Back button & Close X
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: KidColors.cardDark,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded, size: 22),
                              tooltip: 'Exit to Home',
                              onPressed: onBack,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                              tooltip: 'Close panel',
                              onPressed: onClose,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Current video info card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: KidColors.surfaceDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: KidColors.borderDark, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _cleanTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (video.quality.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: KidColors.primary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: KidColors.primary.withValues(alpha: 0.4), width: 0.6),
                                      ),
                                      child: Text(
                                        video.quality,
                                        style: const TextStyle(
                                          fontFamily: 'Roboto',
                                          color: KidColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  if (video.durationFormatted.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      video.durationFormatted,
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        color: KidColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Divider(color: KidColors.borderDark, height: 1),
                        const SizedBox(height: 12),

                        // Controls List
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              // Toddler Lock Tile
                              _buildActionTile(
                                icon: Icons.lock_outline_rounded,
                                title: 'Toddler Lock',
                                subtitle: 'Lock touches while watching',
                                color: KidColors.yellow,
                                onTap: () {
                                  onClose();
                                  onLock();
                                },
                              ),
                              const SizedBox(height: 8),

                              // Audio Mute/Unmute Tile
                              _buildActionTile(
                                icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                title: isMuted ? 'Unmute Audio' : 'Mute Audio',
                                subtitle: isMuted ? 'Sound is currently off' : 'Playing at full volume',
                                color: isMuted ? Colors.white60 : KidColors.primary,
                                onTap: onToggleMute,
                              ),
                              const SizedBox(height: 8),

                              // Orientation Switch Tile (for wide player)
                              if (!isShort)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: KidColors.surfaceDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: KidColors.borderDark, width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Orientation',
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Cycle Auto / Landscape / Portrait',
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              color: KidColors.textMuted,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      OrientationModeSwitch(size: 20, color: Colors.white),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Bottom Profile Badge
                        if (childAvatarIcon != null || onAvatarTap != null) ...[
                          const Divider(color: KidColors.borderDark, height: 1),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              onClose();
                              onAvatarTap?.call();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: Row(
                                children: [
                                  ChildAvatar(
                                    avatarIcon: childAvatarIcon,
                                    radius: 16,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Switch Profile',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: KidColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: KidColors.borderDark, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: KidColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
