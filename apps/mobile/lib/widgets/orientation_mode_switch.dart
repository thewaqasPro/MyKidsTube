import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// Top Bar / Toolbar Orientation Mode Switcher
/// Direct 3-way toggle button cycling between Portrait -> Landscape -> Auto Rotate (no dropdown)
class OrientationModeSwitch extends StatelessWidget {
  final bool compact;
  final Color? backgroundColor;
  final Color? color;
  final double size;

  const OrientationModeSwitch({
    super.key,
    this.compact = true,
    this.backgroundColor,
    this.color,
    this.size = 20,
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

    switch (mode) {
      case AppOrientationMode.portrait:
        icon = Icons.stay_current_portrait_rounded;
        label = 'Portrait';
        break;
      case AppOrientationMode.landscape:
        icon = Icons.stay_current_landscape_rounded;
        label = 'Landscape';
        break;
      case AppOrientationMode.auto:
        icon = Icons.screen_rotation_rounded;
        label = 'Auto Rotate';
        break;
    }

    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: 'Orientation: $label (Tap to toggle)',
      icon: Icon(
        icon,
        color: color ?? Colors.white,
        size: size,
      ),
      onPressed: () {
        final next = _nextMode(mode);
        provider.setOrientationMode(next);
      },
    );
  }
}
