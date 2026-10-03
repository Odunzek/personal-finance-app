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
  group('without parts', () {
    test('the planned cost is the item\'s own estimate', () {
      final totals = WishlistTotals.of(_item(price: 50000), []);
      expect(totals.hasParts, isFalse);
      expect(totals.budgetMinorUnits, 50000);
      expect(totals.plannedMinorUnits, 50000);
      expect(totals.remainingMinorUnits, 50000);
    });

    test('a bought item has nothing remaining', () {
      final totals = WishlistTotals.of(_item(price: 50000, isDone: true), []);
      expect(totals.acquiredMinorUnits, 50000);
      expect(totals.remainingMinorUnits, 0);
    });

    test('an item with no price totals zero rather than crashing', () {
      final totals = WishlistTotals.of(_item(), []);
      expect(totals.plannedMinorUnits, 0);
      expect(totals.remainingMinorUnits, 0);
      expect(totals.isOverBudget, isFalse);
    });
  });

  group('budget vs parts', () {
    test('the budget survives being broken into parts', () {
      final totals = WishlistTotals.of(_item(price: 120000), [
        _part(1, price: 30000),
        _part(2, price: 12500),
      ]);
      expect(totals.budgetMinorUnits, 120000);
      expect(totals.partsTotalMinorUnits, 42500);
      expect(totals.isOverBudget, isFalse);
    });

    test('parts under the budget report how far under', () {
      final totals = WishlistTotals.of(_item(price: 100000), [
        _part(1, price: 40000),
      ]);
      expect(totals.overByMinorUnits, -60000);
      expect(totals.isOverBudget, isFalse);
    });

    test('parts over the budget flag it and report the overrun', () {
      final totals = WishlistTotals.of(_item(price: 100000), [
        _part(1, price: 80000),
        _part(2, price: 45000),
      ]);
      expect(totals.partsTotalMinorUnits, 125000);
      expect(totals.isOverBudget, isTrue);
      expect(totals.overByMinorUnits, 25000);
    });

    test('exactly on budget is not over', () {
      final totals = WishlistTotals.of(_item(price: 50000), [
        _part(1, price: 20000),
        _part(2, price: 30000),
      ]);
      expect(totals.isOverBudget, isFalse);
      expect(totals.overByMinorUnits, 0);
    });

    test('parts with no budget to compare against are never over', () {
      final totals = WishlistTotals.of(_item(), [_part(1, price: 90000)]);
      expect(totals.hasBudget, isFalse);
      expect(totals.isOverBudget, isFalse);
      // With no budget set, the parts themselves are the plan.
      expect(totals.plannedMinorUnits, 90000);
    });
  });

  group('progress', () {
    test('bought parts count toward acquired and reduce what is left', () {
      final totals = WishlistTotals.of(_item(price: 60000), [
        _part(1, price: 30000, isDone: true),
        _part(2, price: 12500),
        _part(3, price: 7500),
      ]);
      expect(totals.acquiredPartCount, 1);
      expect(totals.acquiredMinorUnits, 30000);
      // Remaining follows the parts, which are what will actually be bought.
      expect(totals.remainingMinorUnits, 20000);
    });

    test('parts without a price count toward progress but not cost', () {
      final totals = WishlistTotals.of(_item(), [
        _part(1, price: 10000, isDone: true),
        _part(2, isDone: true),
      ]);
      expect(totals.partCount, 2);
      expect(totals.acquiredPartCount, 2);
      expect(totals.partsTotalMinorUnits, 10000);
      expect(totals.acquiredMinorUnits, 10000);
    });

    test('every part bought leaves nothing remaining', () {
      final totals = WishlistTotals.of(_item(price: 10000), [
        _part(1, price: 5000, isDone: true),
        _part(2, price: 2500, isDone: true),
      ]);
      expect(totals.remainingMinorUnits, 0);
      expect(totals.acquiredPartCount, totals.partCount);
    });

    test('an item ticked off outright has nothing remaining, parts or not', () {
      final totals = WishlistTotals.of(_item(price: 10000, isDone: true), [
        _part(1, price: 5000),
      ]);
      expect(totals.remainingMinorUnits, 0);
    });
  });
}
