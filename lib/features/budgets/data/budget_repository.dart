import '../../../core/models/budget.dart';
import '../../../core/supabase/supabase_client.dart';

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-01';

abstract class BudgetRepository {
  Future<List<Budget>> listBudgetsForMonth(int profileId, DateTime month);
  Future<Budget> upsertBudget({
    required int profileId,
    required int categoryId,
    required DateTime month,
    required int limitMinorUnits,
  });
  Future<void> deleteBudget(int id);

  Future<SavingsTarget?> getSavingsTarget(int profileId, DateTime month);
  Future<SavingsTarget> upsertSavingsTarget({
    required int profileId,
    required DateTime month,
    required int targetMinorUnits,
  });

  /// Permanently deletes every budget and savings target for a profile —
  /// used by the Settings "Reset data" action.
  Future<void> deleteAllForProfile(int profileId);
}

class SupabaseBudgetRepository implements BudgetRepository {
  @override
  Future<List<Budget>> listBudgetsForMonth(
    int profileId,
    DateTime month,
  ) async {
    final rows = await supabase
        .from('budgets')
        .select()
        .eq('profile_id', profileId)
        .eq('month', _dateOnly(month));
    return (rows as List)
        .map((r) => Budget.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Budget> upsertBudget({
    required int profileId,
    required int categoryId,
    required DateTime month,
    required int limitMinorUnits,
  }) async {
    final row = await supabase
        .from('budgets')
        .upsert({
          'profile_id': profileId,
          'category_id': categoryId,
          'month': _dateOnly(month),
          'limit_minor_units': limitMinorUnits,
        }, onConflict: 'profile_id,category_id,month')
        .select()
        .single();
    return Budget.fromRow(row);
  }

  @override
  Future<void> deleteBudget(int id) async {
    await supabase.from('budgets').delete().eq('id', id);
  }

  @override
  Future<SavingsTarget?> getSavingsTarget(int profileId, DateTime month) async {
    final row = await supabase
        .from('savings_targets')
        .select()
        .eq('profile_id', profileId)
        .eq('month', _dateOnly(month))
        .maybeSingle();
    if (row == null) return null;
    return SavingsTarget.fromRow(row);
  }

  @override
  Future<SavingsTarget> upsertSavingsTarget({
    required int profileId,
    required DateTime month,
    required int targetMinorUnits,
  }) async {
    final row = await supabase
        .from('savings_targets')
        .upsert({
          'profile_id': profileId,
          'month': _dateOnly(month),
          'target_minor_units': targetMinorUnits,
        }, onConflict: 'profile_id,month')
        .select()
        .single();
    return SavingsTarget.fromRow(row);
  }

  @override
  Future<void> deleteAllForProfile(int profileId) async {
    await supabase.from('budgets').delete().eq('profile_id', profileId);
    await supabase.from('savings_targets').delete().eq('profile_id', profileId);
  }
}
