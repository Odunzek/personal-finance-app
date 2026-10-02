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

  /// Every part of every item in [itemIds], in one round-trip — the screen
  /// needs all of them at once to total each item up.
  Future<List<WishlistPart>> listParts(List<int> itemIds);

  Future<WishlistPart> createPart({
    required int wishlistItemId,
    required String name,
    int? estimatedPriceMinorUnits,
  });

  Future<void> setPartDone(int id, bool isDone);

  Future<void> deletePart(int id);
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

  @override
  Future<List<WishlistPart>> listParts(List<int> itemIds) async {
    if (itemIds.isEmpty) return [];
    final rows = await supabase
        .from('wishlist_parts')
        .select()
        .inFilter('wishlist_item_id', itemIds)
        .order('sort_order')
        .order('created_at');
    return (rows as List)
        .map((r) => WishlistPart.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WishlistPart> createPart({
    required int wishlistItemId,
    required String name,
    int? estimatedPriceMinorUnits,
  }) async {
    final row = await supabase
        .from('wishlist_parts')
        .insert({
          'wishlist_item_id': wishlistItemId,
          'name': name,
          'estimated_price_minor_units': estimatedPriceMinorUnits,
        })
        .select()
        .single();
    return WishlistPart.fromRow(row);
  }

  @override
  Future<void> setPartDone(int id, bool isDone) async {
    await supabase
        .from('wishlist_parts')
        .update({'is_done': isDone})
        .eq('id', id);
  }

  @override
  Future<void> deletePart(int id) async {
    await supabase.from('wishlist_parts').delete().eq('id', id);
  }
}
