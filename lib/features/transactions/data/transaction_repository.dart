import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart';
import '../../../core/supabase/supabase_client.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> listTransactions(
    int profileId, {
    DateTime? from,
    DateTime? to,
    int? categoryId,
    CategoryType? type,
  });

  Future<List<Transaction>> listRecent(int profileId, {int limit = 5});

  Future<Transaction> createTransaction({
    required int profileId,
    required int categoryId,
    required int amountMinorUnits,
    required CategoryType type,
    required DateTime occurredAt,
    String? note,
  });

  Future<void> updateTransaction(
    int id, {
    int? categoryId,
    int? amountMinorUnits,
    String? note,
  });

  Future<void> deleteTransaction(int id);

  /// Permanently deletes every transaction for a profile — used by the
  /// Settings "Reset data" action. Categories and the profile itself are
  /// untouched.
  Future<void> deleteAllForProfile(int profileId);
}

class SupabaseTransactionRepository implements TransactionRepository {
  @override
  Future<List<Transaction>> listTransactions(
    int profileId, {
    DateTime? from,
    DateTime? to,
    int? categoryId,
    CategoryType? type,
  }) async {
    var query = supabase
        .from('transactions')
        .select()
        .eq('profile_id', profileId);
    if (from != null) {
      query = query.gte('occurred_at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      query = query.lt('occurred_at', to.toUtc().toIso8601String());
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (type != null) {
      query = query.eq('type', type.toDb());
    }
    final rows = await query.order('occurred_at', ascending: false);
    return (rows as List)
        .map((r) => Transaction.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Transaction>> listRecent(int profileId, {int limit = 5}) async {
    final rows = await supabase
        .from('transactions')
        .select()
        .eq('profile_id', profileId)
        .order('occurred_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => Transaction.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Transaction> createTransaction({
    required int profileId,
    required int categoryId,
    required int amountMinorUnits,
    required CategoryType type,
    required DateTime occurredAt,
    String? note,
  }) async {
    final row = await supabase
        .from('transactions')
        .insert({
          'profile_id': profileId,
          'category_id': categoryId,
          'amount_minor_units': amountMinorUnits,
          'type': type.toDb(),
          'occurred_at': occurredAt.toUtc().toIso8601String(),
          'note': note,
        })
        .select()
        .single();
    return Transaction.fromRow(row);
  }

  @override
  Future<void> updateTransaction(
    int id, {
    int? categoryId,
    int? amountMinorUnits,
    String? note,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (categoryId != null) updates['category_id'] = categoryId;
    if (amountMinorUnits != null) {
      updates['amount_minor_units'] = amountMinorUnits;
    }
    if (note != null) updates['note'] = note;
    await supabase.from('transactions').update(updates).eq('id', id);
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await supabase.from('transactions').delete().eq('id', id);
  }

  @override
  Future<void> deleteAllForProfile(int profileId) async {
    await supabase.from('transactions').delete().eq('profile_id', profileId);
  }
}
