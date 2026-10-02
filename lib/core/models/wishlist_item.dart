class WishlistItem {
  final int id;
  final int profileId;
  final String name;
  final int? estimatedPriceMinorUnits;
  final int? categoryId;
  final bool isDone;
  final DateTime createdAt;

  const WishlistItem({
    required this.id,
    required this.profileId,
    required this.name,
    required this.estimatedPriceMinorUnits,
    required this.categoryId,
    required this.isDone,
    required this.createdAt,
  });

  factory WishlistItem.fromRow(Map<String, dynamic> row) {
    return WishlistItem(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      name: row['name'] as String,
      estimatedPriceMinorUnits: row['estimated_price_minor_units'] as int?,
      categoryId: row['category_id'] as int?,
      isDone: row['is_done'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
