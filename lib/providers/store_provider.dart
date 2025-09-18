import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moduels.dart';
import '../services/supabase_service.dart';
import 'auth_providers.dart';

final storesStreamProvider = StreamProvider<List<Store>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(<Store>[]);
  }

  return SupabaseService.client
      .from('stores')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id) // Filter by current user
      .order('priority', ascending: true)
      .map((rows) {
        // Debug: print the raw data to see what we're getting
        print('Raw stores data: $rows');
        final stores = rows.map((m) => Store.fromMap(m)).toList();
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

final addStoreProvider = FutureProvider.family<void, ({String name, int? priority})>((ref, args) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to add stores');
  }
  
  await client.from('stores').insert({
    'name': args.name,
    'priority': args.priority,
    'user_id': user.id,
  });
});

final addStoreItemProvider = FutureProvider.family<void, ({String storeId, String ingredientName})>((ref, args) async {
  final client = SupabaseService.client;
  
  print('Adding ingredient "${args.ingredientName}" to store "${args.storeId}"');
  
  // First, find or create the ingredient
  final ingredientResponse = await client
      .from('ingredients')
      .select('id')
      .eq('name', args.ingredientName)
      .maybeSingle();
  
  String ingredientId;
  if (ingredientResponse != null) {
    ingredientId = ingredientResponse['id'] as String;
    print('Found existing ingredient with ID: $ingredientId');
  } else {
    // Create new ingredient
    print('Creating new ingredient: ${args.ingredientName}');
    final newIngredient = await client
        .from('ingredients')
        .insert({'name': args.ingredientName})
        .select('id')
        .single();
    ingredientId = newIngredient['id'] as String;
    print('Created new ingredient with ID: $ingredientId');
  }
  
  // Then add the store item
  print('Adding store item: store_id=${args.storeId}, ingredient_id=$ingredientId');
  await client.from('store_items').insert({
    'store_id': args.storeId,
    'ingredient_id': ingredientId,
  });
  
  print('Successfully added ingredient to store');
});

// Provider for reordering stores (auto-assigning priority based on position)
final reorderStoresProvider = FutureProvider.family<void, List<String>>((ref, storeIds) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to reorder stores');
  }
  
  print('Reordering stores: ${storeIds.length} stores');
  
  // Update priority for each store based on its position (1-based index)
  for (int i = 0; i < storeIds.length; i++) {
    final storeId = storeIds[i];
    final priority = i + 1; // 1-based priority (1 = highest priority)
    
    print('Updating store $storeId to priority $priority');
    
    await client
        .from('stores')
        .update({'priority': priority})
        .eq('id', storeId)
        .eq('user_id', user.id);
  }
  
  print('Store reordering complete!');
});

// Provider to search stores by ingredient name
final searchStoresByIngredientProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, ingredientName) async {
  if (ingredientName.trim().isEmpty) {
    return [];
  }
  
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to search stores');
  }
  
  // Search for stores that have this ingredient
  final results = await client
      .from('store_items')
      .select('''
        store_id,
        stores!inner(
          id,
          name,
          priority
        ),
        ingredients!inner(
          name
        )
      ''')
      .eq('stores.user_id', user.id)
      .ilike('ingredients.name', '%${ingredientName.trim()}%');
  
  // Group by store and return unique stores
  final Map<String, Map<String, dynamic>> uniqueStores = {};
  
  for (final result in results) {
    final store = result['stores'] as Map<String, dynamic>;
    final storeId = store['id'] as String;
    
    if (!uniqueStores.containsKey(storeId)) {
      uniqueStores[storeId] = {
        'store_id': storeId,
        'store_name': store['name'],
        'priority': store['priority'],
      };
    }
  }
  
  // Convert to list and sort by priority
  final storeList = uniqueStores.values.toList();
  storeList.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));
  
  return storeList;
});
