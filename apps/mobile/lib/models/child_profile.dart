class ChildProfile {
  final String id;
  final String name;
  final String avatarIcon;
  final String ageBracket;

  ChildProfile({
    required this.id,
    required this.name,
    this.avatarIcon = 'bear',
    this.ageBracket = 'all',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_icon': avatarIcon,
      'age_bracket': ageBracket,
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarIcon: map['avatar_icon'] as String? ?? 'bear',
      ageBracket: map['age_bracket'] as String? ?? 'all',
    );
  }

  String get emojiAvatar {
    switch (avatarIcon) {
      case 'rocket':
        return '🚀';
      case 'lion':
        return '🦁';
      case 'unicorn':
        return '🦄';
      case 'panda':
        return '🐼';
      case 'star':
      case 'stars':
        return '⭐';
      case 'teddy':
        return '🧸';
      case 'bear':
      default:
        return '🐻';
    }
  }
}
