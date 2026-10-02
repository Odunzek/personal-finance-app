import '../../../core/models/profile.dart';
import '../../../core/supabase/supabase_client.dart';

abstract class ProfileRepository {
  Future<List<Profile>> listProfiles();
  Future<Profile> createProfile({
    required String displayName,
    required String currencyCode,
    ProfileType type = ProfileType.personal,
  });
  Future<void> renameProfile(int id, String displayName);

  /// Soft-delete: archives the profile and everything under it instead of
  /// cascading a hard delete — same rule as categories and accounts, so one
  /// confirmation tap can never irrecoverably destroy a whole ledger.
  Future<void> deleteProfile(int id);
}

class SupabaseProfileRepository implements ProfileRepository {
  @override
  Future<List<Profile>> listProfiles() async {
    final rows = await supabase
        .from('profiles')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((r) => Profile.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Profile> createProfile({
    required String displayName,
    required String currencyCode,
    ProfileType type = ProfileType.personal,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase
        .from('profiles')
        .insert({
          'owner_user_id': userId,
          'display_name': displayName,
          'currency_code': currencyCode,
          'profile_type': type.toDb(),
        })
        .select()
        .single();
    return Profile.fromRow(row);
  }

  @override
  Future<void> renameProfile(int id, String displayName) async {
    await supabase
        .from('profiles')
        .update({'display_name': displayName})
        .eq('id', id);
  }

  @override
  Future<void> deleteProfile(int id) async {
    await supabase.from('profiles').update({'is_active': false}).eq('id', id);
  }
}
