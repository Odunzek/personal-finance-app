import '../../features/recurring/data/recurring_rule_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';

/// Catches up every due (or overdue) recurring rule for a profile by
/// creating the real transaction(s) it represents and advancing its
/// next-due-date — run once when a profile's home is opened, since there's
/// no background process to fire these on their actual due date.
class RecurringRuleRunner {
  RecurringRuleRunner._();

  /// A rule dormant for a long time (app unused for months) catches up at
  /// most this many occurrences in one pass, so a stale weekly rule can't
  /// flood the ledger with hundreds of backfilled transactions.
  static const _maxCatchUpPerRule = 24;

  /// Returns true if any transaction was created, so the caller can refresh.
  static Future<bool> catchUp({
    required RecurringRuleRepository recurringRuleRepository,
    required TransactionRepository transactionRepository,
    required int profileId,
  }) async {
    final rules = await recurringRuleRepository.listActiveRules(profileId);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    var createdAny = false;
    for (final rule in rules) {
      var due = rule.nextDueDate;
      var iterations = 0;
      while (!due.isAfter(todayDateOnly) && iterations < _maxCatchUpPerRule) {
        await transactionRepository.createTransaction(
          profileId: rule.profileId,
          accountId: rule.accountId,
          categoryId: rule.categoryId,
          amountMinorUnits: rule.amountMinorUnits,
          type: rule.type,
          occurredAt: due,
          note: rule.note,
          recurringRuleId: rule.id,
        );
        createdAny = true;
        due = rule.frequency.next(due);
        iterations++;
      }
      if (iterations > 0) {
        await recurringRuleRepository.advanceRule(rule.id, due);
      }
    }
    return createdAny;
  }
}
