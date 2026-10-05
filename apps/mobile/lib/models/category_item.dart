class CategoryItem {
  final String id;
  final String name;
  final String icon;
  final int displayOrder;

  CategoryItem({
    required this.id,
    required this.name,
    this.icon = 'category',
    this.displayOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'display_order': displayOrder,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? 'category',
      displayOrder: map['display_order'] as int? ?? 0,
    );
  }
}
