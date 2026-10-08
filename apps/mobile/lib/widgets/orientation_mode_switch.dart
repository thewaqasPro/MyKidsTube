import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Top Bar / Toolbar Orientation Mode Switcher
/// Compact icon-only button with a sleek popup menu for Landscape, Portrait, and Auto
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
        label = 'Landscape';
        accentColor = KidColors.accent;
        break;
      case AppOrientationMode.auto:
        icon = Icons.screen_rotation_rounded;
        label = 'Auto Rotate';
        accentColor = KidColors.mint;
        break;
    }

    return PopupMenuButton<AppOrientationMode>(
      tooltip: label,
      initialValue: mode,
      onSelected: (newMode) => provider.setOrientationMode(newMode),
      color: KidColors.cardDark,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: KidColors.borderDark),
      ),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor ?? KidColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
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
        child: Center(
          child: Icon(icon, size: 18, color: accentColor),
        ),
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: AppOrientationMode.landscape,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stay_current_landscape_rounded,
                color: mode == AppOrientationMode.landscape ? KidColors.accent : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Landscape',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: mode == AppOrientationMode.landscape ? KidColors.accent : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: AppOrientationMode.portrait,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stay_current_portrait_rounded,
                color: mode == AppOrientationMode.portrait ? KidColors.sky : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Portrait',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: mode == AppOrientationMode.portrait ? KidColors.sky : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: AppOrientationMode.auto,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.screen_rotation_rounded,
                color: mode == AppOrientationMode.auto ? KidColors.mint : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Auto Rotate',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: mode == AppOrientationMode.auto ? KidColors.mint : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
