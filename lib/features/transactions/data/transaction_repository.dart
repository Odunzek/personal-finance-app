import '../../../core/models/transaction.dart';
import '../../../core/supabase/supabase_client.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> listTransactions(
    int profileId, {
    DateTime? from,
    DateTime? to,
    int? categoryId,
    int? accountId,
    TransactionKind? type,
  });

  Future<List<Transaction>> listRecent(int profileId, {int limit = 5});

  Future<Transaction> createTransaction({
    required int profileId,
    required int accountId,
    required int categoryId,
    required int amountMinorUnits,
    required TransactionKind type,
    required DateTime occurredAt,
    String? note,
    int? recurringRuleId,
  });

  /// Moves money from [fromAccountId] to [toAccountId] — e.g. paying a
  /// credit card from checking. Has no category and never counts as income
  /// or expense; it only moves balance between the two accounts.
  Future<Transaction> createTransfer({
    required int profileId,
    required int fromAccountId,
    required int toAccountId,
    required int amountMinorUnits,
    required DateTime occurredAt,
    String? note,
    int? recurringRuleId,
  });

  Future<void> updateTransaction(
    int id, {
    int? categoryId,
    int? amountMinorUnits,
    DateTime? occurredAt,
    String? note,
  });

  Future<void> deleteTransaction(int id);

  /// Permanently deletes every transaction for a profile — used by the
  /// Settings "Reset data" action. Categories, accounts, and the profile
  /// itself are untouched.
  Future<void> deleteAllForProfile(int profileId);
}

class SupabaseTransactionRepository implements TransactionRepository {
  @override
  Future<List<Transaction>> listTransactions(
    int profileId, {
    DateTime? from,
    DateTime? to,
    int? categoryId,
    int? accountId,
    TransactionKind? type,
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
    if (accountId != null) {
      query = query.eq('account_id', accountId);
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
    required int accountId,
    required int categoryId,
    required int amountMinorUnits,
    required TransactionKind type,
    required DateTime occurredAt,
    String? note,
    int? recurringRuleId,
  }) async {
    final row = await supabase
        .from('transactions')
        .insert({
          'profile_id': profileId,
          'account_id': accountId,
          'category_id': categoryId,
          'amount_minor_units': amountMinorUnits,
          'type': type.toDb(),
          'occurred_at': occurredAt.toUtc().toIso8601String(),
          'note': note,
          'recurring_rule_id': recurringRuleId,
        })
        .select()
        .single();
    return Transaction.fromRow(row);
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
    final row = await supabase
        .from('transactions')
        .insert({
          'profile_id': profileId,
          'account_id': fromAccountId,
          'transfer_account_id': toAccountId,
          'category_id': null,
          'amount_minor_units': amountMinorUnits,
          'type': TransactionKind.transfer.toDb(),
          'occurred_at': occurredAt.toUtc().toIso8601String(),
          'note': note,
          'recurring_rule_id': recurringRuleId,
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
    DateTime? occurredAt,
    String? note,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (categoryId != null) updates['category_id'] = categoryId;
    if (amountMinorUnits != null) {
      updates['amount_minor_units'] = amountMinorUnits;
    }
    if (occurredAt != null) {
      updates['occurred_at'] = occurredAt.toUtc().toIso8601String();
    }
    // An empty string is an explicit "clear the note" (stored as NULL,
    // matching how creation stores absent notes); null means "leave as-is".
    // Without this, a note once set could never be removed.
    if (note != null) {
      updates['note'] = note.trim().isEmpty ? null : note.trim();
    }
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
