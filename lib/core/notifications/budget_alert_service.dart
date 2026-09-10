import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/budgets/data/budget_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';
import '../models/month_range.dart';
import '../models/transaction.dart';
import 'reminder_service.dart';

/// Warns once when a category's spending for the current month crosses 80%
/// and again when it crosses 100% of its budget. "Once" is tracked in
/// secure storage per profile/category/month/threshold, so re-saving more
/// expenses in the same category doesn't re-notify every time — the key
/// naturally resets itself once the month rolls over.
class BudgetAlertService {
  BudgetAlertService._();

  static const _storage = FlutterSecureStorage();

  static Future<void> checkThresholds({
    required BudgetRepository budgetRepository,
    required TransactionRepository transactionRepository,
    required int profileId,
    required int categoryId,
    required String categoryName,
  }) async {
    final month = MonthRange.current();
    final budgets = await budgetRepository.listBudgetsForMonth(
      profileId,
      month.start,
    );
    final budget = budgets.where((b) => b.categoryId == categoryId).firstOrNull;
    if (budget == null || budget.limitMinorUnits <= 0) return;

    final expenses = await transactionRepository.listTransactions(
      profileId,
      categoryId: categoryId,
      from: month.start,
      to: month.endExclusive,
      type: TransactionKind.expense,
    );
    final spent = expenses.fold<int>(0, (sum, t) => sum + t.amountMinorUnits);
    final ratio = spent / budget.limitMinorUnits;
    final monthKey = '${month.start.year}-${month.start.month}';

    if (ratio >= 1.0) {
      await _notifyOnce(
        key: 'budget_100_${profileId}_${categoryId}_$monthKey',
        title: 'Budget exceeded',
        body: '$categoryName has gone over its budget for this month.',
      );
    } else if (ratio >= 0.8) {
      await _notifyOnce(
        key: 'budget_80_${profileId}_${categoryId}_$monthKey',
        title: 'Budget nearly reached',
        body:
            '$categoryName is at ${(ratio * 100).round()}% of its budget for this month.',
      );
    }
  }

  static Future<void> _notifyOnce({
    required String key,
    required String title,
    required String body,
  }) async {
    final already = await _storage.read(key: key);
    if (already == 'true') return;
    await _storage.write(key: key, value: 'true');
    await ReminderService.instance.notifyNow(
      id: key.hashCode,
      title: title,
      body: body,
    );
  }
}
