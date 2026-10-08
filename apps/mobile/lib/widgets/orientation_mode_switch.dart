import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Top Bar Orientation Mode Switcher
/// Allows toggling and locking between Portrait and YouTube Kids Landscape mode
class OrientationModeSwitch extends StatelessWidget {
  final bool compact;
  final Color? backgroundColor;

  const OrientationModeSwitch({
    super.key,
    this.compact = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final mode = provider.orientationMode;

    final IconData icon;
    final String label;
    final Color accentColor;

    switch (mode) {
      case AppOrientationMode.portrait:
        icon = Icons.stay_current_portrait_rounded;
        label = 'Portrait';
        accentColor = KidColors.sky;
        break;
      case AppOrientationMode.landscape:
        icon = Icons.stay_current_landscape_rounded;
        label = 'Kids Landscape';
        accentColor = KidColors.accent;
        break;
      case AppOrientationMode.auto:
        icon = Icons.screen_rotation_rounded;
        label = 'Auto Rotate';
        accentColor = KidColors.mint;
        break;
    }

    if (compact) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showOrientationSheet(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: backgroundColor ?? KidColors.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: accentColor),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Full button variant
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? KidColors.surfaceDark,
        foregroundColor: accentColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      onPressed: () => _showOrientationSheet(context, provider),
    );
  }

  void _showOrientationSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: KidColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: KidColors.borderDark, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KidColors.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.screen_rotation_rounded, color: KidColors.accent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Screen Orientation & Layout',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Lock into YouTube Kids side-by-side landscape mode or portrait mode to prevent phone flipping.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  color: KidColors.textMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // Option 1: Kids Landscape (Side-by-side)
              _buildOptionTile(
                context: ctx,
                title: 'Kids Landscape Mode (Locked)',
                subtitle: 'Side-by-side: Video on left, scrolling playlist on right',
                icon: Icons.stay_current_landscape_rounded,
                accentColor: KidColors.accent,
                isSelected: provider.orientationMode == AppOrientationMode.landscape,
                onTap: () {
                  Navigator.of(ctx).pop();
                  provider.setOrientationMode(AppOrientationMode.landscape);
                },
              ),
              const SizedBox(height: 10),

              // Option 2: Portrait (Vertical)
              _buildOptionTile(
                context: ctx,
                title: 'Portrait Mode (Locked)',
                subtitle: 'Standard vertical feed and player with list below',
                icon: Icons.stay_current_portrait_rounded,
                accentColor: KidColors.sky,
                isSelected: provider.orientationMode == AppOrientationMode.portrait,
                onTap: () {
                  Navigator.of(ctx).pop();
                  provider.setOrientationMode(AppOrientationMode.portrait);
                },
              ),
              const SizedBox(height: 10),

              // Option 3: Auto Rotate
              _buildOptionTile(
                context: ctx,
                title: 'Auto-Rotate',
                subtitle: 'Rotates automatically with device tilt sensor',
                icon: Icons.screen_rotation_rounded,
                accentColor: KidColors.mint,
                isSelected: provider.orientationMode == AppOrientationMode.auto,
                onTap: () {
                  Navigator.of(ctx).pop();
                  provider.setOrientationMode(AppOrientationMode.auto);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.12) : KidColors.cardElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? accentColor : KidColors.borderDark,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : KidColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11.5,
                        color: KidColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: accentColor, size: 20)
              else
                const Icon(Icons.circle_outlined, color: KidColors.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
