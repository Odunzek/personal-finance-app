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

  /// Updates any subset of a transaction's fields. Passing [type] rewrites the
  /// row's whole shape — category and transfer columns together — because the
  /// database requires an income/expense row to have a category and no
  /// transfer destination, and a transfer the exact reverse; changing one
  /// column without the other is rejected. So [categoryId] is required
  /// alongside an income/expense [type], and [transferAccountId] alongside a
  /// transfer [type].
  Future<void> updateTransaction(
    int id, {
    int? categoryId,
    int? amountMinorUnits,
    DateTime? occurredAt,
    String? note,
    int? accountId,
    TransactionKind? type,
    int? transferAccountId,
  });

  /// Moves every transaction in [ids] to [categoryId] in one round-trip, and
  /// sets each one's [type] to match that category's own type — otherwise an
  /// expense dropped into an income category would contradict its category
  /// and be counted on the wrong side of every total. Transfers have no
  /// category, so they must not be included in [ids].
  Future<void> recategorizeTransactions({
    required List<int> ids,
    required int categoryId,
    required TransactionKind type,
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
    int? accountId,
    TransactionKind? type,
    int? transferAccountId,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (type != null) {
      updates['type'] = type.toDb();
      if (type == TransactionKind.transfer) {
        if (transferAccountId == null) {
          throw ArgumentError('A transfer needs a destination account.');
        }
        updates['transfer_account_id'] = transferAccountId;
        updates['category_id'] = null;
      } else {
        if (categoryId == null) {
          throw ArgumentError('An ${type.name} needs a category.');
        }
        updates['category_id'] = categoryId;
        updates['transfer_account_id'] = null;
      }
    } else if (categoryId != null) {
      updates['category_id'] = categoryId;
    }
    if (accountId != null) updates['account_id'] = accountId;
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
  Future<void> recategorizeTransactions({
    required List<int> ids,
    required int categoryId,
    required TransactionKind type,
  }) async {
    if (ids.isEmpty) return;
    await supabase
        .from('transactions')
        .update({
          'category_id': categoryId,
          'type': type.toDb(),
          'transfer_account_id': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .inFilter('id', ids);
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
