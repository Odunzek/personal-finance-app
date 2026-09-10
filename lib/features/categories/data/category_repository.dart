import '../../../core/models/category.dart';
import '../../../core/supabase/supabase_client.dart';

abstract class CategoryRepository {
  Future<List<Category>> listActiveCategories(int profileId);
  Future<Category> createCategory({
    required int profileId,
    required String name,
    required CategoryType type,
    required int colorArgb,
    required String iconKey,
  });
  Future<void> renameCategory(int id, String name);
  Future<void> recolorCategory(int id, int colorArgb);

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
  Future<void> deactivateCategory(int id) async {
    await supabase
        .from('categories')
        .update({'is_active': false})
        .eq('id', id);
  }
}
