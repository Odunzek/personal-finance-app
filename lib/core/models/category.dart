enum CategoryType {
  income,
  expense;

  String toDb() => name;

  static CategoryType fromDb(String value) =>
      CategoryType.values.firstWhere((t) => t.name == value);
}

class Category {
  final int id;
  final int profileId;
  final String name;
  final CategoryType type;
  final int colorArgb;
  final String iconKey;
  final bool isActive;
  final int sortOrder;

  const Category({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
    required this.colorArgb,
    required this.iconKey,
    required this.isActive,
    required this.sortOrder,
  });

  factory Category.fromRow(Map<String, dynamic> row) {
    return Category(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      name: row['name'] as String,
      type: CategoryType.fromDb(row['type'] as String),
      colorArgb: row['color_argb'] as int,
      iconKey: row['icon_key'] as String,
      isActive: row['is_active'] as bool,
      sortOrder: row['sort_order'] as int,
    );
  }
}
