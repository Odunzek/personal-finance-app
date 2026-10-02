import '../../../core/models/category.dart';
import '../../../core/models/default_categories.dart';
import '../../../core/supabase/supabase_client.dart';

abstract class CategoryRepository {
  Future<List<Category>> listActiveCategories(int profileId);

  /// Includes deactivated categories — for history and name resolution
  /// (exports, trends breakdowns), where a removed category's past spend
  /// must keep its name instead of vanishing or exporting blank.
  Future<List<Category>> listAllCategories(int profileId);
  Future<Category> createCategory({
    required int profileId,
    required String name,
    required CategoryType type,
    required int colorArgb,
    required String iconKey,
  });

  /// One round-trip for seeding a new profile's defaults — a loop of
  /// individual inserts could fail halfway and leave a half-seeded profile.
  Future<void> createCategories(int profileId, List<DefaultCategorySeed> seeds);
  Future<void> renameCategory(int id, String name);
  Future<void> recolorCategory(int id, int colorArgb);
  Future<void> reiconCategory(int id, String iconKey);

  /// Soft-delete only. Categories are never hard-deleted once they may be
  /// referenced by transactions — see CLAUDE.md.
  Future<void> deactivateCategory(int id);
}

class SupabaseCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> listActiveCategories(int profileId) async {
    final rows = await supabase
        .from('categories')
        .select()
        .eq('profile_id', profileId)
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((r) => Category.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createCategories(
    int profileId,
    List<DefaultCategorySeed> seeds,
  ) async {
    if (seeds.isEmpty) return;
    await supabase.from('categories').insert([
      for (final seed in seeds)
        {
          'profile_id': profileId,
          'name': seed.name,
          'type': seed.type.toDb(),
          'color_argb': seed.colorArgb,
          'icon_key': seed.iconKey,
        },
    ]);
  }

  @override
  Future<List<Category>> listAllCategories(int profileId) async {
    final rows = await supabase
        .from('categories')
        .select()
        .eq('profile_id', profileId)
        .order('sort_order');
    return (rows as List)
        .map((r) => Category.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Category> createCategory({
    required int profileId,
    required String name,
    required CategoryType type,
    required int colorArgb,
    required String iconKey,
  }) async {
    final row = await supabase
        .from('categories')
        .insert({
          'profile_id': profileId,
          'name': name,
          'type': type.toDb(),
          'color_argb': colorArgb,
          'icon_key': iconKey,
        })
        .select()
        .single();
    return Category.fromRow(row);
  }

  @override
  Future<void> renameCategory(int id, String name) async {
    await supabase.from('categories').update({'name': name}).eq('id', id);
  }

  @override
  Future<void> recolorCategory(int id, int colorArgb) async {
    await supabase
        .from('categories')
        .update({'color_argb': colorArgb})
        .eq('id', id);
  }

  @override
  Future<void> reiconCategory(int id, String iconKey) async {
    await supabase
        .from('categories')
        .update({'icon_key': iconKey})
        .eq('id', id);
  }

  @override
  Future<void> deactivateCategory(int id) async {
    await supabase.from('categories').update({'is_active': false}).eq('id', id);
  }
}
