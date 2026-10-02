import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/models/account.dart';
import 'package:finance_app/core/models/account_balance.dart';
import 'package:finance_app/core/models/transaction.dart';

Account _account(
  int id, {
  int startingBalance = 0,
  AccountType type = AccountType.asset,
}) {
  return Account(
    id: id,
    profileId: 1,
    name: 'Account $id',
    type: type,
    debtKind: null,
    startingBalanceMinorUnits: startingBalance,
    isActive: true,
    sortOrder: 0,
  );
}

Transaction _tx(
  int id, {
  required int accountId,
  required TransactionKind type,
  required int amount,
  int? categoryId,
  int? transferAccountId,
}) {
  return Transaction(
    id: id,
    profileId: 1,
    accountId: accountId,
    categoryId: categoryId,
    transferAccountId: transferAccountId,
    amountMinorUnits: amount,
    type: type,
    occurredAt: DateTime(2026, 1, id),
  );
}

void main() {
  group('computeAccountBalance', () {
    test('starts from the starting balance with no transactions', () {
      expect(
        computeAccountBalance(_account(1, startingBalance: 5000), []),
        5000,
      );
    });

    test('adds income and subtracts expenses on the account', () {
      final txs = [
        _tx(
          1,
          accountId: 1,
          type: TransactionKind.income,
          amount: 10000,
          categoryId: 1,
        ),
        _tx(
          2,
          accountId: 1,
          type: TransactionKind.expense,
          amount: 2500,
          categoryId: 2,
        ),
      ];
      expect(computeAccountBalance(_account(1), txs), 7500);
    });

    test('ignores transactions on other accounts', () {
      final txs = [
        _tx(
          1,
          accountId: 2,
          type: TransactionKind.income,
          amount: 10000,
          categoryId: 1,
        ),
      ];
      expect(computeAccountBalance(_account(1), txs), 0);
    });

    test(
      'a transfer moves balance out of the source and into the destination',
      () {
        final txs = [
          _tx(
            1,
            accountId: 1,
            type: TransactionKind.transfer,
            amount: 3000,
            transferAccountId: 2,
          ),
        ];
        expect(
          computeAccountBalance(_account(1, startingBalance: 10000), txs),
          7000,
        );
        expect(computeAccountBalance(_account(2), txs), 3000);
      },
    );

    test('a liability with negative starting balance moves toward zero when paid down', () {
      final card = _account(
        2,
        startingBalance: -50000,
        type: AccountType.liability,
      );
      final txs = [
        _tx(
          1,
          accountId: 1,
          type: TransactionKind.transfer,
          amount: 20000,
          transferAccountId: 2,
        ),
      ];
      expect(computeAccountBalance(card, txs), -30000);
    });

    test('net worth sums to zero change across both sides of a transfer', () {
      final a = _account(1, startingBalance: 10000);
      final b = _account(2, startingBalance: 500);
      final txs = [
        _tx(
          1,
          accountId: 1,
          type: TransactionKind.transfer,
          amount: 4000,
          transferAccountId: 2,
        ),
      ];
      final net = computeAccountBalance(a, txs) + computeAccountBalance(b, txs);
      expect(net, 10500);
    });
  });
}
