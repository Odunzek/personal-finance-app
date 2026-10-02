import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/models/wishlist_item.dart';

WishlistItem _item({int? price, bool isDone = false}) => WishlistItem(
  id: 1,
  profileId: 1,
  name: 'Home server',
  estimatedPriceMinorUnits: price,
  categoryId: null,
  isDone: isDone,
  createdAt: DateTime(2026, 1, 1),
);

WishlistPart _part(int id, {int? price, bool isDone = false}) => WishlistPart(
  id: id,
  wishlistItemId: 1,
  name: 'Part $id',
  estimatedPriceMinorUnits: price,
  isDone: isDone,
);

void main() {
  group('WishlistTotals without parts', () {
    test('falls back to the item\'s own estimate', () {
      final totals = WishlistTotals.of(_item(price: 50000), []);
      expect(totals.hasParts, isFalse);
      expect(totals.totalMinorUnits, 50000);
      expect(totals.remainingMinorUnits, 50000);
    });

    test('a bought item has nothing remaining', () {
      final totals = WishlistTotals.of(_item(price: 50000, isDone: true), []);
      expect(totals.acquiredMinorUnits, 50000);
      expect(totals.remainingMinorUnits, 0);
    });

    test('an item with no price at all totals zero rather than crashing', () {
      final totals = WishlistTotals.of(_item(), []);
      expect(totals.totalMinorUnits, 0);
      expect(totals.remainingMinorUnits, 0);
    });
  });

  group('WishlistTotals with parts', () {
    test('the total is the sum of the parts, not the item estimate', () {
      final totals = WishlistTotals.of(_item(price: 999999), [
        _part(1, price: 30000),
        _part(2, price: 12500),
      ]);
      expect(totals.hasParts, isTrue);
      expect(totals.partCount, 2);
      expect(totals.totalMinorUnits, 42500);
    });

    test('bought parts count toward acquired and reduce what is left', () {
      final totals = WishlistTotals.of(_item(), [
        _part(1, price: 30000, isDone: true),
        _part(2, price: 12500),
        _part(3, price: 7500),
      ]);
      expect(totals.acquiredPartCount, 1);
      expect(totals.acquiredMinorUnits, 30000);
      expect(totals.remainingMinorUnits, 20000);
    });

    test('parts without a price count toward progress but not cost', () {
      final totals = WishlistTotals.of(_item(), [
        _part(1, price: 10000, isDone: true),
        _part(2, isDone: true),
      ]);
      expect(totals.partCount, 2);
      expect(totals.acquiredPartCount, 2);
      expect(totals.totalMinorUnits, 10000);
      expect(totals.acquiredMinorUnits, 10000);
    });

    test('every part bought leaves nothing remaining', () {
      final totals = WishlistTotals.of(_item(), [
        _part(1, price: 5000, isDone: true),
        _part(2, price: 2500, isDone: true),
      ]);
      expect(totals.remainingMinorUnits, 0);
      expect(totals.acquiredPartCount, totals.partCount);
    });
  });
}
