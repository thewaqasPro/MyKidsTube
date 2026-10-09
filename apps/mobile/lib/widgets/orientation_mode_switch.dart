import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Top Bar / Toolbar Orientation Mode Switcher
/// Direct 3-way toggle button cycling between Portrait -> Landscape -> Auto Rotate (no dropdown)
class OrientationModeSwitch extends StatelessWidget {
  final bool compact;
  final Color? backgroundColor;

  const OrientationModeSwitch({
    super.key,
    this.compact = true,
    this.backgroundColor,
  });

  AppOrientationMode _nextMode(AppOrientationMode current) {
    switch (current) {
      case AppOrientationMode.portrait:
        return AppOrientationMode.landscape;
      case AppOrientationMode.landscape:
        return AppOrientationMode.auto;
      case AppOrientationMode.auto:
        return AppOrientationMode.portrait;
    }
  }

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

    final size = compact ? 30.0 : 36.0;

    return Tooltip(
      message: 'Orientation: $label (Tap to toggle)',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final next = _nextMode(mode);
          provider.setOrientationMode(next);
        },
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: backgroundColor ?? KidColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, size: compact ? 16 : 18, color: accentColor),
          ),
        ),
      ),
    );
  }
}
