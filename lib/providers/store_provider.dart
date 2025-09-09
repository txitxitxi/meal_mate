import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

final storesStreamProvider = StreamProvider<List<Store>>((ref) {
  return SupabaseService.client
      .from('stores')
      .stream(primaryKey: ['id'])
      .order('priority')
      .map((rows) => rows.map((m) => Store.fromMap(m)).toList());
});

final storeItemsProvider = StreamProvider.family<List<StoreItem>, String>((ref, storeId) {
  return SupabaseService.client
      .from('store_items')
      .stream(primaryKey: ['id'])
      .eq('store_id', storeId)
      .map((rows) => rows.map((m) => StoreItem.fromMap(m)).toList());
});

final addStoreProvider = FutureProvider.family<void, ({String name, bool isDefault, int? priority})>((ref, args) async {
  await SupabaseService.client.from('stores').insert({
    'name': args.name,
    'is_default': args.isDefault,
    'priority': args.priority,
  });
});

final addStoreItemProvider = FutureProvider.family<void, ({String storeId, String ingredientName})>((ref, args) async {
  await SupabaseService.client.from('store_items').insert({
    'store_id': args.storeId,
    'ingredient_name': args.ingredientName,
  });
});
