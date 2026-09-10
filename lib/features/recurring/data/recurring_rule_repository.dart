import '../../../core/models/recurring_rule.dart';
import '../../../core/models/transaction.dart';
import '../../../core/supabase/supabase_client.dart';

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

abstract class RecurringRuleRepository {
  Future<List<RecurringRule>> listActiveRules(int profileId);

  Future<RecurringRule> createRule({
    required int profileId,
    required int accountId,
    required int categoryId,
    required TransactionKind type,
    required int amountMinorUnits,
    required RecurringFrequency frequency,
    required DateTime nextDueDate,
    String? note,
  });

  Future<void> advanceRule(int id, DateTime nextDueDate);
  Future<void> deactivateRule(int id);

  /// Permanently deletes every recurring rule for a profile — used by the
  /// Settings "Reset data" action.
  Future<void> deleteAllForProfile(int profileId);
}

class SupabaseRecurringRuleRepository implements RecurringRuleRepository {
  @override
  Future<List<RecurringRule>> listActiveRules(int profileId) async {
    final rows = await supabase
        .from('recurring_rules')
        .select()
        .eq('profile_id', profileId)
        .eq('is_active', true)
        .order('next_due_date');
    return (rows as List)
        .map((r) => RecurringRule.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RecurringRule> createRule({
    required int profileId,
    required int accountId,
    required int categoryId,
    required TransactionKind type,
    required int amountMinorUnits,
    required RecurringFrequency frequency,
    required DateTime nextDueDate,
    String? note,
  }) async {
    final row = await supabase
        .from('recurring_rules')
        .insert({
          'profile_id': profileId,
          'account_id': accountId,
          'category_id': categoryId,
          'type': type.toDb(),
          'amount_minor_units': amountMinorUnits,
          'frequency': frequency.toDb(),
          'next_due_date': _dateOnly(nextDueDate),
          'note': note,
        })
        .select()
        .single();
    return RecurringRule.fromRow(row);
  }

  @override
  Future<void> advanceRule(int id, DateTime nextDueDate) async {
    await supabase
        .from('recurring_rules')
        .update({'next_due_date': _dateOnly(nextDueDate)})
        .eq('id', id);
  }

  @override
  Future<void> deactivateRule(int id) async {
    await supabase
        .from('recurring_rules')
        .update({'is_active': false})
        .eq('id', id);
  }

  @override
  Future<void> deleteAllForProfile(int profileId) async {
    await supabase.from('recurring_rules').delete().eq('profile_id', profileId);
  }
}
