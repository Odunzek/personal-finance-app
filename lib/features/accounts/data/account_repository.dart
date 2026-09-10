import '../../../core/models/account.dart';
import '../../../core/supabase/supabase_client.dart';

abstract class AccountRepository {
  Future<List<Account>> listActiveAccounts(int profileId);

  Future<Account> createAccount({
    required int profileId,
    required String name,
    required AccountType type,
    required int startingBalanceMinorUnits,
  });

  Future<void> renameAccount(int id, String name);

  /// Soft-delete only, same rule as categories — an account referenced by
  /// transactions is never hard-deleted.
  Future<void> deactivateAccount(int id);
}

class SupabaseAccountRepository implements AccountRepository {
  @override
  Future<List<Account>> listActiveAccounts(int profileId) async {
    final rows = await supabase
        .from('accounts')
        .select()
        .eq('profile_id', profileId)
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((r) => Account.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Account> createAccount({
    required int profileId,
    required String name,
    required AccountType type,
    required int startingBalanceMinorUnits,
  }) async {
    final row = await supabase
        .from('accounts')
        .insert({
          'profile_id': profileId,
          'name': name,
          'type': type.toDb(),
          'starting_balance_minor_units': startingBalanceMinorUnits,
        })
        .select()
        .single();
    return Account.fromRow(row);
  }

  @override
  Future<void> renameAccount(int id, String name) async {
    await supabase.from('accounts').update({'name': name}).eq('id', id);
  }

  @override
  Future<void> deactivateAccount(int id) async {
    await supabase.from('accounts').update({'is_active': false}).eq('id', id);
  }
}
