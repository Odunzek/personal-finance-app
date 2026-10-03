import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/export/statement_pdf.dart';
import 'package:finance_app/core/models/account.dart';
import 'package:finance_app/core/models/transaction.dart';

Account _account(
  int id, {
  int opening = 0,
  AccountType type = AccountType.asset,
}) => Account(
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

final _from = DateTime(2026, 9, 1);
final _to = DateTime(2026, 10, 1);

void main() {
  // The worked example: a $500 laptop bought in August on Klarna, carried as
  // Klarna's opening balance. In September: $120 groceries, a $200 payment to
  // Klarna, $80 fuel. Real September spending is $200, not $400.
  const cashId = 1;
  const klarnaId = 2;
  final cash = _account(cashId, opening: 200000);
  final klarna = _account(
    klarnaId,
    opening: -50000,
    type: AccountType.liability,
  );

  final september = [
    _tx(
      1,
      accountId: cashId,
      type: TransactionKind.expense,
      amount: 12000,
      on: DateTime(2026, 9, 3),
      categoryId: 1,
    ),
    _tx(
      2,
      accountId: cashId,
      type: TransactionKind.transfer,
      amount: 20000,
      on: DateTime(2026, 9, 10),
      transferAccountId: klarnaId,
    ),
    _tx(
      3,
      accountId: cashId,
      type: TransactionKind.expense,
      amount: 8000,
      on: DateTime(2026, 9, 20),
      categoryId: 2,
    ),
  ];

  group('the debt-payment scenario', () {
    test('a debt payment is not counted as an expense', () {
      final s = buildStatementSection(cash, september, _from, _to);
      expect(s.expenseMinorUnits, 20000); // $120 + $80 only
      expect(s.transferOutMinorUnits, 20000); // the $200 payment, separately
    });

    test('but it still leaves the account and moves the balance', () {
      final s = buildStatementSection(cash, september, _from, _to);
      expect(s.totalOutMinorUnits, 40000); // all $400 really left Cash
      expect(s.closingMinorUnits, 160000); // $2,000 - $400
      expect(s.rows, hasLength(3)); // and all three rows are printed
    });

    test('the same payment arrives as money in on the debt account', () {
      final s = buildStatementSection(klarna, september, _from, _to);
      expect(s.transferInMinorUnits, 20000);
      expect(s.expenseMinorUnits, 0);
      // Debt reduced from $500 owed to $300 owed.
      expect(s.openingMinorUnits, -50000);
      expect(s.closingMinorUnits, -30000);
    });

    test('spending matches the fall in net worth, which 400 would not', () {
      final cashSection = buildStatementSection(cash, september, _from, _to);
      final klarnaSection = buildStatementSection(
        klarna,
        september,
        _from,
        _to,
      );
      final openingNetWorth =
          cashSection.openingMinorUnits + klarnaSection.openingMinorUnits;
      final closingNetWorth =
          cashSection.closingMinorUnits + klarnaSection.closingMinorUnits;
      expect(openingNetWorth - closingNetWorth, 20000);
      expect(
        cashSection.expenseMinorUnits + klarnaSection.expenseMinorUnits,
        openingNetWorth - closingNetWorth,
      );
    });
  });

  group('opening balance', () {
    test('carries everything before the period, not just the start value', () {
      final august = [
        _tx(
          9,
          accountId: cashId,
          type: TransactionKind.expense,
          amount: 50000,
          on: DateTime(2026, 8, 15),
          categoryId: 1,
        ),
        ...september,
      ];
      final s = buildStatementSection(cash, august, _from, _to);
      expect(s.openingMinorUnits, 150000); // $2,000 - $500 spent in August
      expect(s.rows, hasLength(3)); // August's row is not in the period
    });

    test('transactions after the period are excluded entirely', () {
      final withOctober = [
        ...september,
        _tx(
          10,
          accountId: cashId,
          type: TransactionKind.expense,
          amount: 9900,
          on: DateTime(2026, 10, 2),
          categoryId: 1,
        ),
      ];
      final s = buildStatementSection(cash, withOctober, _from, _to);
      expect(s.rows, hasLength(3));
      expect(s.closingMinorUnits, 160000);
    });

    test('the final day of the period is included', () {
      final onLastDay = [
        _tx(
          11,
          accountId: cashId,
          type: TransactionKind.expense,
          amount: 1000,
          on: DateTime(2026, 9, 30, 18, 30),
          categoryId: 1,
        ),
      ];
      final s = buildStatementSection(cash, onLastDay, _from, _to);
      expect(s.rows, hasLength(1));
      expect(s.expenseMinorUnits, 1000);
    });
  });

  group('closing balance', () {
    test('equals opening plus everything that moved', () {
      final s = buildStatementSection(cash, september, _from, _to);
      expect(
        s.closingMinorUnits,
        s.openingMinorUnits + s.totalInMinorUnits - s.totalOutMinorUnits,
      );
    });

    test('an account with no activity still reports its opening balance', () {
      final idle = _account(99, opening: 4500);
      final s = buildStatementSection(idle, september, _from, _to);
      expect(s.rows, isEmpty);
      expect(s.openingMinorUnits, 4500);
      expect(s.closingMinorUnits, 4500);
    });
  });
}
