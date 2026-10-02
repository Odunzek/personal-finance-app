import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/export/transactions_csv.dart';
import 'package:finance_app/core/models/account.dart';
import 'package:finance_app/core/models/category.dart';
import 'package:finance_app/core/models/transaction.dart';

const _cash = Account(
  id: 1,
  profileId: 1,
  name: 'Cash',
  type: AccountType.asset,
  debtKind: null,
  startingBalanceMinorUnits: 0,
  isActive: true,
  sortOrder: 0,
);

const _savings = Account(
  id: 2,
  profileId: 1,
  name: 'Savings',
  type: AccountType.asset,
  debtKind: null,
  startingBalanceMinorUnits: 0,
  isActive: true,
  sortOrder: 1,
);

const _groceries = Category(
  id: 1,
  profileId: 1,
  name: 'Groceries',
  type: CategoryType.expense,
  colorArgb: 0xFF000000,
  iconKey: 'other',
  isActive: true,
  sortOrder: 0,
);

Transaction _tx(
  int id, {
  required TransactionKind type,
  required int amount,
  int? categoryId,
  int? transferAccountId,
  String? note,
  DateTime? occurredAt,
}) {
  return Transaction(
    id: id,
    profileId: 1,
    accountId: 1,
    categoryId: categoryId,
    transferAccountId: transferAccountId,
    amountMinorUnits: amount,
    type: type,
    occurredAt: occurredAt ?? DateTime(2026, 3, 5),
    note: note,
  );
}

String _buildCsv(List<Transaction> txs) => buildTransactionsCsv(
  transactions: txs,
  categoriesById: {1: _groceries},
  accountsById: {1: _cash, 2: _savings},
);

void main() {
  group('buildTransactionsCsv', () {
    test('writes header and one row per transaction, newest first', () {
      final csv = _buildCsv([
        _tx(
          1,
          type: TransactionKind.expense,
          amount: 1250,
          categoryId: 1,
          occurredAt: DateTime(2026, 1, 1),
        ),
        _tx(
          2,
          type: TransactionKind.income,
          amount: 50000,
          categoryId: 1,
          occurredAt: DateTime(2026, 2, 1),
        ),
      ]);
      final lines = csv.trim().split('\n');
      expect(lines, hasLength(3));
      expect(lines[0], 'Date,Type,Account,Category,Note,Amount');
      expect(lines[1], startsWith('2026-02-01,Income'));
      expect(lines[2], startsWith('2026-01-01,Expense'));
    });

    test('expenses are negative dollars, income positive', () {
      final csv = _buildCsv([
        _tx(1, type: TransactionKind.expense, amount: 1250, categoryId: 1),
      ]);
      expect(csv, contains('-12.50'));
    });

    test('a transfer names the destination account in the category column', () {
      final csv = _buildCsv([
        _tx(
          1,
          type: TransactionKind.transfer,
          amount: 3000,
          transferAccountId: 2,
        ),
      ]);
      expect(csv, contains('Transfer,Cash,Savings'));
    });

    test('quotes fields containing commas', () {
      final csv = _buildCsv([
        _tx(
          1,
          type: TransactionKind.expense,
          amount: 100,
          categoryId: 1,
          note: 'milk, eggs',
        ),
      ]);
      expect(csv, contains('"milk, eggs"'));
    });

    test('doubles embedded quotes', () {
      final csv = _buildCsv([
        _tx(
          1,
          type: TransactionKind.expense,
          amount: 100,
          categoryId: 1,
          note: 'the "good" bread',
        ),
      ]);
      expect(csv, contains('"the ""good"" bread"'));
    });

    test('quotes fields containing newlines', () {
      final csv = _buildCsv([
        _tx(
          1,
          type: TransactionKind.expense,
          amount: 100,
          categoryId: 1,
          note: 'line one\nline two',
        ),
      ]);
      expect(csv, contains('"line one\nline two"'));
    });

    test('unknown category or account falls back to empty, not a crash', () {
      final csv = buildTransactionsCsv(
        transactions: [
          _tx(1, type: TransactionKind.expense, amount: 100, categoryId: 99),
        ],
        categoriesById: const {},
        accountsById: const {},
      );
      expect(csv.trim().split('\n'), hasLength(2));
    });
  });
}
