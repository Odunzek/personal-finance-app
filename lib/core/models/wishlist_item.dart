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

/// One piece of a larger wishlist item — the drives and PSU that make up a
/// home server, say. An item with parts is costed from them rather than from
/// its own single estimate.
class WishlistPart {
  final int id;
  final int wishlistItemId;
  final String name;
  final int? estimatedPriceMinorUnits;
  final bool isDone;

  const WishlistPart({
    required this.id,
    required this.wishlistItemId,
    required this.name,
    required this.estimatedPriceMinorUnits,
    required this.isDone,
  });

  factory WishlistPart.fromRow(Map<String, dynamic> row) {
    return WishlistPart(
      id: row['id'] as int,
      wishlistItemId: row['wishlist_item_id'] as int,
      name: row['name'] as String,
      estimatedPriceMinorUnits: row['estimated_price_minor_units'] as int?,
      isDone: row['is_done'] as bool,
    );
  }
}

/// What an item costs and how far along it is, whether its total comes from
/// its own estimate or from the parts it was broken into.
class WishlistTotals {
  final int totalMinorUnits;
  final int acquiredMinorUnits;
  final int partCount;
  final int acquiredPartCount;

  const WishlistTotals({
    required this.totalMinorUnits,
    required this.acquiredMinorUnits,
    required this.partCount,
    required this.acquiredPartCount,
  });

  bool get hasParts => partCount > 0;
  int get remainingMinorUnits => totalMinorUnits - acquiredMinorUnits;

  static WishlistTotals of(WishlistItem item, List<WishlistPart> parts) {
    if (parts.isEmpty) {
      final own = item.estimatedPriceMinorUnits ?? 0;
      return WishlistTotals(
        totalMinorUnits: own,
        acquiredMinorUnits: item.isDone ? own : 0,
        partCount: 0,
        acquiredPartCount: 0,
      );
    }
    var total = 0;
    var acquired = 0;
    var acquiredCount = 0;
    for (final p in parts) {
      final price = p.estimatedPriceMinorUnits ?? 0;
      total += price;
      if (p.isDone) {
        acquired += price;
        acquiredCount++;
      }
    }
    return WishlistTotals(
      totalMinorUnits: total,
      acquiredMinorUnits: acquired,
      partCount: parts.length,
      acquiredPartCount: acquiredCount,
    );
  }
}
