import '../../../core/models/wishlist_item.dart';
import '../../../core/supabase/supabase_client.dart';

abstract class WishlistRepository {
  Future<List<WishlistItem>> listItems(int profileId);

  Future<WishlistItem> createItem({
    required int profileId,
    required String name,
    int? estimatedPriceMinorUnits,
    int? categoryId,
  });

  Future<void> setDone(int id, bool isDone);

  Future<void> deleteItem(int id);
}

class SupabaseWishlistRepository implements WishlistRepository {
  @override
  Future<List<WishlistItem>> listItems(int profileId) async {
    final rows = await supabase
        .from('wishlist_items')
        .select()
        .eq('profile_id', profileId)
        .order('is_done')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => WishlistItem.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WishlistItem> createItem({
    required int profileId,
    required String name,
    int? estimatedPriceMinorUnits,
    int? categoryId,
  }) async {
    final row = await supabase
        .from('wishlist_items')
        .insert({
          'profile_id': profileId,
          'name': name,
          'estimated_price_minor_units': estimatedPriceMinorUnits,
          'category_id': categoryId,
        })
        .select()
        .single();
    return WishlistItem.fromRow(row);
  }

  @override
  Future<void> setDone(int id, bool isDone) async {
    await supabase
        .from('wishlist_items')
        .update({'is_done': isDone})
        .eq('id', id);
  }

  @override
  Future<void> deleteItem(int id) async {
    await supabase.from('wishlist_items').delete().eq('id', id);
  }
}
