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

  static ChildProfile? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    if (id == null || id.toString().trim().isEmpty) return null;
    return ChildProfile(
      id: id.toString(),
      name: (map['name'] ?? 'Child').toString(),
      avatarIcon: (map['avatar_icon'] ?? 'bear').toString(),
      ageBracket: (map['age_bracket'] ?? 'all').toString(),
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
