import 'package:flutter/material.dart';

class ChildAvatar extends StatelessWidget {
  final String? avatarIcon;
  final double radius;
  final bool showBorder;

  const ChildAvatar({
    super.key,
    this.avatarIcon,
    this.radius = 18,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getAvatarConfig(avatarIcon ?? 'bear');

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: config.gradientColors,
        ),
        border: showBorder
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: config.gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          config.icon,
          size: radius * 1.15,
          color: Colors.white,
        ),
      ),
    );
  }

  _AvatarConfig _getAvatarConfig(String iconKey) {
    switch (iconKey.toLowerCase().trim()) {
      case 'rocket':
        return _AvatarConfig(
          icon: Icons.rocket_launch_rounded,
          gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
        );
      case 'lion':
        return _AvatarConfig(
          icon: Icons.cruelty_free_rounded,
          gradientColors: [const Color(0xFFF97316), const Color(0xFFEA580C)],
        );
      case 'unicorn':
        return _AvatarConfig(
          icon: Icons.auto_awesome_rounded,
          gradientColors: [const Color(0xFFEC4899), const Color(0xFFD946EF)],
        );
      case 'panda':
        return _AvatarConfig(
          icon: Icons.smart_toy_rounded,
          gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
        );
      case 'star':
      case 'stars':
        return _AvatarConfig(
          icon: Icons.star_rounded,
          gradientColors: [const Color(0xFFEAB308), const Color(0xFFCA8A04)],
        );
      case 'teddy':
        return _AvatarConfig(
          icon: Icons.sentiment_very_satisfied_rounded,
          gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        );
      case 'bear':
      default:
        return _AvatarConfig(
          icon: Icons.pets_rounded,
          gradientColors: [const Color(0xFFE53935), const Color(0xFFC62828)],
        );
    }
  }
}

class _AvatarConfig {
  final IconData icon;
  final List<Color> gradientColors;

  _AvatarConfig({required this.icon, required this.gradientColors});
}
