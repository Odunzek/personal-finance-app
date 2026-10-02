import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:finance_app/core/models/recurring_rule.dart';
import 'package:finance_app/core/models/transaction.dart';
import 'package:finance_app/core/recurring/recurring_rule_runner.dart';
import 'package:finance_app/features/recurring/data/recurring_rule_repository.dart';
import 'package:finance_app/features/transactions/data/transaction_repository.dart';

class _FakeRuleRepository implements RecurringRuleRepository {
  final List<RecurringRule> rules;
  final Map<int, DateTime> advancedTo = {};
  int advanceCalls = 0;

  _FakeRuleRepository(this.rules);

  @override
  Future<List<RecurringRule>> listActiveRules(int profileId) async =>
      rules.where((r) => r.profileId == profileId && r.isActive).toList();

  @override
  Future<void> advanceRule(int id, DateTime nextDueDate) async {
    advancedTo[id] = nextDueDate;
    advanceCalls++;
  }

  @override
  Future<RecurringRule> createRule({
    required int profileId,
    required int accountId,
    int? categoryId,
    int? toAccountId,
    required TransactionKind type,
    required int amountMinorUnits,
    required RecurringFrequency frequency,
    required DateTime nextDueDate,
    String? note,
  }) async => throw UnimplementedError();

  @override
  Future<void> deactivateRule(int id) async {}

  @override
  Future<void> deleteAllForProfile(int profileId) async {}
}

class _RecordingTransactionRepository implements TransactionRepository {
  final List<DateTime> createdOccurrences = [];
  final List<DateTime> createdTransferOccurrences = [];

  /// Occurrence dates that throw the duplicate-key error, simulating a
  /// second device having already created them.
  final Set<DateTime> duplicateDates;

  _RecordingTransactionRepository({this.duplicateDates = const {}});

  @override
  Future<Transaction> createTransaction({
    required int profileId,
    required int accountId,
    required int categoryId,
    required int amountMinorUnits,
    required TransactionKind type,
    required DateTime occurredAt,
    String? note,
    int? recurringRuleId,
  }) async {
    if (duplicateDates.contains(occurredAt)) {
      throw PostgrestException(message: 'duplicate key', code: '23505');
    }
    createdOccurrences.add(occurredAt);
    return Transaction(
      id: createdOccurrences.length,
      profileId: profileId,
      accountId: accountId,
      categoryId: categoryId,
      transferAccountId: null,
      amountMinorUnits: amountMinorUnits,
      type: type,
      occurredAt: occurredAt,
      recurringRuleId: recurringRuleId,
    );
  }

  @override
  Future<Transaction> createTransfer({
    required int profileId,
    required int fromAccountId,
    required int toAccountId,
    required int amountMinorUnits,
    required DateTime occurredAt,
    String? note,
    int? recurringRuleId,
  }) async {
    createdTransferOccurrences.add(occurredAt);
    return Transaction(
      id: createdTransferOccurrences.length,
      profileId: profileId,
      accountId: fromAccountId,
      categoryId: null,
      transferAccountId: toAccountId,
      amountMinorUnits: amountMinorUnits,
      type: TransactionKind.transfer,
      occurredAt: occurredAt,
      recurringRuleId: recurringRuleId,
    );
  }

  @override
  Future<List<Transaction>> listTransactions(
    int profileId, {
    DateTime? from,
    DateTime? to,
    int? categoryId,
    int? accountId,
    TransactionKind? type,
  }) async => [];

  @override
  Future<List<Transaction>> listRecent(int profileId, {int limit = 5}) async =>
      [];

  @override
  Future<void> updateTransaction(
    int id, {
    int? categoryId,
    int? amountMinorUnits,
    DateTime? occurredAt,
    String? note,
    int? accountId,
    TransactionKind? type,
    int? transferAccountId,
  }) async {}

  @override
  Future<void> recategorizeTransactions({
    required List<int> ids,
    required int categoryId,
    required TransactionKind type,
  }) async {}

  @override
  Future<void> deleteTransaction(int id) async {}

  @override
  Future<void> deleteAllForProfile(int profileId) async {}
}

RecurringRule _rule({
  int id = 1,
  required DateTime nextDue,
  RecurringFrequency frequency = RecurringFrequency.monthly,
  TransactionKind type = TransactionKind.expense,
  int? toAccountId,
}) {
  return RecurringRule(
    id: id,
    profileId: 1,
    accountId: 1,
    categoryId: type == TransactionKind.transfer ? null : 1,
    toAccountId: toAccountId,
    type: type,
    amountMinorUnits: 1000,
    frequency: frequency,
    nextDueDate: nextDue,
    note: null,
    isActive: true,
  );
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  group('RecurringRuleRunner.catchUp', () {
    test('a rule due in the future creates nothing', () async {
      final rules = _FakeRuleRepository([
        _rule(nextDue: _today().add(const Duration(days: 1))),
      ]);
      final txs = _RecordingTransactionRepository();

      final created = await RecurringRuleRunner.catchUp(
        recurringRuleRepository: rules,
        transactionRepository: txs,
        profileId: 1,
      );

      expect(created, isFalse);
      expect(txs.createdOccurrences, isEmpty);
      expect(rules.advanceCalls, 0);
    });

    test('a rule due today creates one transaction and advances', () async {
      final today = _today();
      final rules = _FakeRuleRepository([_rule(nextDue: today)]);
      final txs = _RecordingTransactionRepository();

      final created = await RecurringRuleRunner.catchUp(
        recurringRuleRepository: rules,
        transactionRepository: txs,
        profileId: 1,
      );

      expect(created, isTrue);
      expect(txs.createdOccurrences, [today]);
      expect(rules.advancedTo[1], RecurringFrequency.monthly.next(today));
    });

    test('an overdue weekly rule backfills every missed occurrence', () async {
      final today = _today();
      final threeWeeksAgo = DateTime(today.year, today.month, today.day - 21);
      final rules = _FakeRuleRepository([
        _rule(nextDue: threeWeeksAgo, frequency: RecurringFrequency.weekly),
      ]);
      final txs = _RecordingTransactionRepository();

      await RecurringRuleRunner.catchUp(
        recurringRuleRepository: rules,
        transactionRepository: txs,
        profileId: 1,
      );

      expect(txs.createdOccurrences, hasLength(4));
      expect(txs.createdOccurrences.first, threeWeeksAgo);
      expect(txs.createdOccurrences.last, today);
      expect(rules.advancedTo[1], RecurringFrequency.weekly.next(today));
    });

    test('advances the rule after every insert, not once at the end', () async {
      final today = _today();
      final rules = _FakeRuleRepository([
        _rule(
          nextDue: DateTime(today.year, today.month, today.day - 7),
          frequency: RecurringFrequency.weekly,
        ),
      ]);
      final txs = _RecordingTransactionRepository();

      await RecurringRuleRunner.catchUp(
        recurringRuleRepository: rules,
        transactionRepository: txs,
        profileId: 1,
      );

      expect(rules.advanceCalls, txs.createdOccurrences.length);
    });

    test('a duplicate occurrence (other device won the race) is skipped '
        'but the rule still advances past it', () async {
      final today = _today();
      final lastWeek = DateTime(today.year, today.month, today.day - 7);
      final rules = _FakeRuleRepository([
        _rule(nextDue: lastWeek, frequency: RecurringFrequency.weekly),
      ]);
      final txs = _RecordingTransactionRepository(duplicateDates: {lastWeek});

      final created = await RecurringRuleRunner.catchUp(
        recurringRuleRepository: rules,
        transactionRepository: txs,
        profileId: 1,
      );

      expect(created, isTrue);
      expect(txs.createdOccurrences, [today]);
      expect(rules.advancedTo[1], RecurringFrequency.weekly.next(today));
    });

    test('a non-duplicate database error propagates', () async {
      final today = _today();
      final rules = _FakeRuleRepository([_rule(nextDue: today)]);
      final txs = _RecordingTransactionRepository(duplicateDates: {});

      final failing = _FailingTransactionRepository();
      expect(
        () => RecurringRuleRunner.catchUp(
          recurringRuleRepository: rules,
          transactionRepository: failing,
          profileId: 1,
        ),
        throwsA(isA<PostgrestException>()),
      );
      expect(txs.createdOccurrences, isEmpty);
    });

    test(
      'a very stale rule is capped instead of flooding the ledger',
      () async {
        final today = _today();
        final twoYearsAgo = DateTime(today.year - 2, today.month, today.day);
        final rules = _FakeRuleRepository([
          _rule(nextDue: twoYearsAgo, frequency: RecurringFrequency.weekly),
        ]);
        final txs = _RecordingTransactionRepository();

        await RecurringRuleRunner.catchUp(
          recurringRuleRepository: rules,
          transactionRepository: txs,
          profileId: 1,
        );

        expect(txs.createdOccurrences, hasLength(24));
      },
    );

    test('a transfer rule creates transfers, not income/expense', () async {
      final today = _today();
      final rules = _FakeRuleRepository([
        _rule(nextDue: today, type: TransactionKind.transfer, toAccountId: 2),
      ]);
      final txs = _RecordingTransactionRepository();

      await RecurringRuleRunner.catchUp(
        recurringRuleRepository: rules,
        transactionRepository: txs,
        profileId: 1,
      );

      expect(txs.createdTransferOccurrences, [today]);
      expect(txs.createdOccurrences, isEmpty);
    });
  });
}

class _FailingTransactionRepository extends _RecordingTransactionRepository {
  @override
  Future<Transaction> createTransaction({
    required int profileId,
    required int accountId,
    required int categoryId,
    required int amountMinorUnits,
    required TransactionKind type,
    required DateTime occurredAt,
    String? note,
    int? recurringRuleId,
  }) async {
    throw PostgrestException(message: 'permission denied', code: '42501');
  }
}
