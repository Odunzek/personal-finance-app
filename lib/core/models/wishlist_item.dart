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

/// What an item is budgeted at, what its parts actually add up to, and how
/// far along it is.
///
/// The item's own estimate stays the budget once it's broken into parts —
/// the parts sum *toward* it rather than replacing it, so overrunning the
/// plan is visible instead of silently becoming the new total.
class WishlistTotals {
  /// The item's own estimate. 0 when none was given.
  final int budgetMinorUnits;

  /// What the parts actually add up to. 0 when there are none.
  final int partsTotalMinorUnits;
  final int acquiredMinorUnits;
  final int partCount;
  final int acquiredPartCount;
  final bool itemIsDone;

  const WishlistTotals({
    required this.budgetMinorUnits,
    required this.partsTotalMinorUnits,
    required this.acquiredMinorUnits,
    required this.partCount,
    required this.acquiredPartCount,
    required this.itemIsDone,
  });

  bool get hasParts => partCount > 0;
  bool get hasBudget => budgetMinorUnits > 0;

  /// What this is currently expected to cost: the parts once they exist,
  /// otherwise the estimate.
  int get plannedMinorUnits =>
      hasParts ? partsTotalMinorUnits : budgetMinorUnits;

  /// Only meaningful with both a budget and parts to compare against it.
  bool get isOverBudget =>
      hasParts && hasBudget && partsTotalMinorUnits > budgetMinorUnits;

  /// Positive when over, negative when the parts still come in under.
  int get overByMinorUnits => partsTotalMinorUnits - budgetMinorUnits;

  /// Still to be bought — what the wishlist header sums.
  int get remainingMinorUnits {
    if (itemIsDone) return 0;
    return plannedMinorUnits - acquiredMinorUnits;
  }

  static WishlistTotals of(WishlistItem item, List<WishlistPart> parts) {
    var partsTotal = 0;
    var acquired = 0;
    var acquiredCount = 0;
    for (final p in parts) {
      final price = p.estimatedPriceMinorUnits ?? 0;
      partsTotal += price;
      if (p.isDone) {
        acquired += price;
        acquiredCount++;
      }
    }
    final budget = item.estimatedPriceMinorUnits ?? 0;
    return WishlistTotals(
      budgetMinorUnits: budget,
      partsTotalMinorUnits: partsTotal,
      // With no parts, a ticked-off item counts its whole estimate as spent.
      acquiredMinorUnits: parts.isEmpty ? (item.isDone ? budget : 0) : acquired,
      partCount: parts.length,
      acquiredPartCount: acquiredCount,
      itemIsDone: item.isDone,
    );
  }
}
