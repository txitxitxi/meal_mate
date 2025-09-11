import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moduels.dart';
import '../services/supabase_service.dart';

final storesStreamProvider = StreamProvider<List<Store>>((ref) {
  return SupabaseService.client
      .from('stores')
      .stream(primaryKey: ['id'])
      .order('is_default', ascending: false)
      .order('priority', ascending: true)
      .map((rows) {
        // Debug: print the raw data to see what we're getting
        print('Raw stores data: $rows');
        final stores = rows.map((m) => Store.fromMap(m)).toList();
        // Sort in Dart as backup to ensure default stores are first
        stores.sort((a, b) {
          if (a.isDefault && !b.isDefault) return -1;
          if (!a.isDefault && b.isDefault) return 1;
          return 0; // Keep original order for same default status
        });
        return stores;
      });
});

final storeItemsProvider = FutureProvider.family<List<StoreItem>, String>((ref, storeId) async {
  final client = SupabaseService.client;
  
  // First get the store items
  final storeItems = await client
      .from('store_items')
      .select('id, store_id, ingredient_id, price, aisle, availability, preferred')
      .eq('store_id', storeId);
  
  // Then get all the ingredient names in one query
  final ingredientIds = storeItems.map((item) => item['ingredient_id'] as String).toList();
  final ingredients = <String, String>{};
  
  if (ingredientIds.isNotEmpty) {
    final ingredientResponse = await client
        .from('ingredients')
        .select('id, name')
        .inFilter('id', ingredientIds);
    
    for (final ing in ingredientResponse) {
      ingredients[ing['id'] as String] = ing['name'] as String;
    }
  }
  
  // Combine the data
  return storeItems.map((item) => StoreItem(
    id: item['id'] as String,
    storeId: item['store_id'] as String,
    ingredientName: ingredients[item['ingredient_id'] as String] ?? 'Unknown',
    price: (item['price'] as num?)?.toDouble(),
    aisle: item['aisle'] as String?,
    availability: item['availability'] as String?,
    preferred: (item['preferred'] as bool?) ?? false,
  )).toList();
});

final addStoreProvider = FutureProvider.family<void, ({String name, bool isDefault, int? priority})>((ref, args) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to add stores');
  }
  
  await client.from('stores').insert({
    'name': args.name,
    'is_default': args.isDefault,
    'priority': args.priority,
    'user_id': user.id,
  });
});

final addStoreItemProvider = FutureProvider.family<void, ({String storeId, String ingredientName})>((ref, args) async {
  final client = SupabaseService.client;
  
  // First, find or create the ingredient
  final ingredientResponse = await client
      .from('ingredients')
      .select('id')
      .eq('name', args.ingredientName)
      .maybeSingle();
  
  String ingredientId;
  if (ingredientResponse != null) {
    ingredientId = ingredientResponse['id'] as String;
  } else {
    // Create new ingredient
    final newIngredient = await client
        .from('ingredients')
        .insert({'name': args.ingredientName})
        .select('id')
        .single();
    ingredientId = newIngredient['id'] as String;
  }
  
  // Then add the store item
  await client.from('store_items').insert({
    'store_id': args.storeId,
    'ingredient_id': ingredientId,
  });
});
