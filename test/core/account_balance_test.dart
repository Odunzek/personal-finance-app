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

    test('a transfer into the account is counted, not dropped', () {
      // The regression this guards: filtering on accountId alone misses the
      // destination side of every transfer.
      final incoming = _tx(
        1,
        accountId: 2,
        type: TransactionKind.transfer,
        amount: 3000,
        transferAccountId: 1,
      );
      expect(transactionTouchesAccount(incoming, 1), isTrue);
      expect(signedAmountForAccount(incoming, 1), 3000);
      expect(computeAccountBalance(_account(1), [incoming]), 3000);
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

  group('per-account filtering', () {
    final expense = _tx(
      1,
      accountId: 1,
      type: TransactionKind.expense,
      amount: 2500,
      categoryId: 1,
    );
    final outgoing = _tx(
      2,
      accountId: 1,
      type: TransactionKind.transfer,
      amount: 3000,
      transferAccountId: 2,
    );
    final elsewhere = _tx(
      3,
      accountId: 3,
      type: TransactionKind.expense,
      amount: 900,
      categoryId: 1,
    );

    test('matches both sides of a transfer and nothing unrelated', () {
      expect(transactionTouchesAccount(expense, 1), isTrue);
      expect(transactionTouchesAccount(outgoing, 1), isTrue);
      expect(transactionTouchesAccount(outgoing, 2), isTrue);
      expect(transactionTouchesAccount(elsewhere, 1), isFalse);
      expect(transactionTouchesAccount(expense, 2), isFalse);
    });

    test(
      'signs each side of a transfer from that account\'s point of view',
      () {
        expect(signedAmountForAccount(outgoing, 1), -3000);
        expect(signedAmountForAccount(outgoing, 2), 3000);
        expect(signedAmountForAccount(outgoing, 3), 0);
      },
    );

    test('income is positive and expense negative on their own account', () {
      final income = _tx(
        4,
        accountId: 1,
        type: TransactionKind.income,
        amount: 5000,
        categoryId: 1,
      );
      expect(signedAmountForAccount(income, 1), 5000);
      expect(signedAmountForAccount(expense, 1), -2500);
    });

    test('the filtered list sums to exactly the account balance', () {
      final all = [expense, outgoing, elsewhere];
      final account = _account(1, startingBalance: 10000);
      final mine = all
          .where((t) => transactionTouchesAccount(t, account.id))
          .toList();
      final summed = mine.fold<int>(
        account.startingBalanceMinorUnits,
        (sum, t) => sum + signedAmountForAccount(t, account.id),
      );
      expect(summed, computeAccountBalance(account, all));
    });
  });
}
