import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/models/account.dart';
import 'package:finance_app/core/models/home_summary.dart';
import 'package:finance_app/core/models/transaction.dart';

Account _account(int id, {required AccountType type, int opening = 0}) =>
    Account(
      id: id,
      profileId: 1,
      name: 'Account $id',
      type: type,
      debtKind: null,
      startingBalanceMinorUnits: opening,
      isActive: true,
      sortOrder: 0,
    );

Transaction _tx(
  int id, {
  required int accountId,
  required TransactionKind type,
  required int amount,
  required DateTime on,
  int? categoryId,
  int? transferAccountId,
}) => Transaction(
  id: id,
  profileId: 1,
  accountId: accountId,
  categoryId: categoryId,
  transferAccountId: transferAccountId,
  amountMinorUnits: amount,
  type: type,
  occurredAt: on,
);

final _monthStart = DateTime(2026, 10, 1);

// Cash with $2,000; a card carrying $500 of debt from before this month.
final _cash = _account(1, type: AccountType.asset, opening: 200000);
final _card = _account(2, type: AccountType.liability, opening: -50000);

void main() {
  group('available', () {
    test('counts asset accounts only, never offset by debt', () {
      final s = HomeSummary.of([_cash, _card], [], _monthStart);
      expect(s.availableMinorUnits, 200000);
      expect(s.owedMinorUnits, 50000);
      // The number people used to see.
      expect(s.netWorthMinorUnits, 150000);
    });

    test('spending reduces it, and it stays positive while cash lasts', () {
      final s = HomeSummary.of(
        [_cash, _card],
        [
          _tx(
            1,
            accountId: 1,
            type: TransactionKind.expense,
            amount: 12000,
            on: DateTime(2026, 10, 3),
            categoryId: 1,
          ),
        ],
        _monthStart,
      );
      expect(s.availableMinorUnits, 188000);
    });

    test('a profile with no debt reports none', () {
      final s = HomeSummary.of([_cash], [], _monthStart);
      expect(s.hasDebt, isFalse);
      expect(s.owedMinorUnits, 0);
    });
  });

  group('debt movement this month', () {
    test('a payment this month shows as debt paid off', () {
      final s = HomeSummary.of(
        [_cash, _card],
        [
          _tx(
            1,
            accountId: 1,
            type: TransactionKind.transfer,
            amount: 20000,
            on: DateTime(2026, 10, 10),
            transferAccountId: 2,
          ),
        ],
        _monthStart,
      );
      expect(s.owedMinorUnits, 30000);
      expect(s.debtPaidThisMonthMinorUnits, 20000);
      expect(s.debtGrewThisMonth, isFalse);
    });

    test('new borrowing shows as debt added, not as progress', () {
      // The trap this guards: counting payments alone would report $200 paid
      // off while the balance actually rose.
      final s = HomeSummary.of(
        [_cash, _card],
        [
          _tx(
            1,
            accountId: 1,
            type: TransactionKind.transfer,
            amount: 20000,
            on: DateTime(2026, 10, 10),
            transferAccountId: 2,
          ),
          _tx(
            2,
            accountId: 2,
            type: TransactionKind.expense,
            amount: 35000,
            on: DateTime(2026, 10, 12),
            categoryId: 1,
          ),
        ],
        _monthStart,
      );
      expect(s.owedMinorUnits, 65000);
      expect(s.debtPaidThisMonthMinorUnits, -15000);
      expect(s.debtGrewThisMonth, isTrue);
    });

    test('last month\'s payments do not count toward this month', () {
      final s = HomeSummary.of(
        [_cash, _card],
        [
          _tx(
            1,
            accountId: 1,
            type: TransactionKind.transfer,
            amount: 20000,
            on: DateTime(2026, 9, 15),
            transferAccountId: 2,
          ),
        ],
        _monthStart,
      );
      expect(s.owedMinorUnits, 30000);
      expect(s.debtPaidThisMonthMinorUnits, 0);
    });

    test('a quiet month reports no movement either way', () {
      final s = HomeSummary.of([_cash, _card], [], _monthStart);
      expect(s.debtPaidThisMonthMinorUnits, 0);
      expect(s.debtGrewThisMonth, isFalse);
    });

    test('paying a debt leaves net worth unchanged', () {
      // Cash down, debt down: the same reason a debt payment is not an
      // expense on the statement.
      final before = HomeSummary.of([_cash, _card], [], _monthStart);
      final after = HomeSummary.of(
        [_cash, _card],
        [
          _tx(
            1,
            accountId: 1,
            type: TransactionKind.transfer,
            amount: 20000,
            on: DateTime(2026, 10, 10),
            transferAccountId: 2,
          ),
        ],
        _monthStart,
      );
      expect(after.availableMinorUnits, lessThan(before.availableMinorUnits));
      expect(after.netWorthMinorUnits, before.netWorthMinorUnits);
    });
  });
}
