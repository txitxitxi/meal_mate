import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moduels.dart';
import '../services/supabase_service.dart';
import 'auth_providers.dart';
import '../utils/logger.dart';

// Add a refresh trigger
final storesRefreshProvider = StateProvider<int>((ref) => 0);

final storesStreamProvider = StreamProvider<List<Store>>((ref) {
  // Watch the refresh trigger to force refresh when needed
  ref.watch(storesRefreshProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    logDebug('No user found, returning empty stores list');
    return Stream.value(<Store>[]);
  }

  logDebug('Fetching stores for user: ${user.id}');
  
  // Use a simple stream with proper user filtering
  return SupabaseService.client
      .from('stores')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id) // Filter by current user
      .order('priority', ascending: true)
      .map((rows) {
        logDebug('Raw stores data for user ${user.id}: $rows');
        
        // Double-check that all stores belong to the current user
        final filteredRows = rows.where((row) {
          final storeUserId = row['user_id'] as String?;
          final belongsToUser = storeUserId == user.id;
          if (!belongsToUser) {
            logDebug('WARNING: Found store ${row['id']} belonging to user $storeUserId, expected ${user.id}');
          }
          return belongsToUser;
        }).toList();
        
        final stores = filteredRows.map((m) => Store.fromMap(m)).toList();
        logDebug('Processed ${stores.length} stores for user ${user.id}');
        return stores;
      });
});

final storeItemsProvider = FutureProvider.family<List<StoreItem>, String>((ref, storeId) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to view store items');
  }
  
  // First verify that the store belongs to the current user
  final store = await client
      .from('stores')
      .select('id, user_id')
      .eq('id', storeId)
      .eq('user_id', user.id)
      .maybeSingle();
  
  if (store == null) {
    logDebug('WARNING: Store $storeId does not belong to user ${user.id}');
    return [];
  }
  
  // Then get the store items
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
  
  logDebug('Adding ingredient "${args.ingredientName}" to store "${args.storeId}"');
  
  // First, find or create the ingredient
  final ingredientResponse = await client
      .from('ingredients')
      .select('id')
      .eq('name', args.ingredientName)
      .maybeSingle();
  
  String ingredientId;
  if (ingredientResponse != null) {
    ingredientId = ingredientResponse['id'] as String;
    logDebug('Found existing ingredient with ID: $ingredientId');
  } else {
    // Create new ingredient
    logDebug('Creating new ingredient: ${args.ingredientName}');
    final newIngredient = await client
        .from('ingredients')
        .insert({'name': args.ingredientName})
        .select('id')
        .single();
    ingredientId = newIngredient['id'] as String;
    logDebug('Created new ingredient with ID: $ingredientId');
  }
  
  // Then add the store item (use upsert to handle case where item might already exist)
  logDebug('Adding store item: store_id=${args.storeId}, ingredient_id=$ingredientId');
  await client.from('store_items').upsert({
    'store_id': args.storeId,
    'ingredient_id': ingredientId,
  }, onConflict: 'store_id,ingredient_id');
  
  logDebug('Successfully added ingredient to store');
});

// Provider for reordering stores (auto-assigning priority based on position)
final reorderStoresProvider = FutureProvider.family<void, List<String>>((ref, storeIds) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to reorder stores');
  }
  
  logDebug('Reordering stores: ${storeIds.length} stores');
  
  // Update priority for each store based on its position (1-based index)
  for (int i = 0; i < storeIds.length; i++) {
    final storeId = storeIds[i];
    final priority = i + 1; // 1-based priority (1 = highest priority)
    
    logDebug('Updating store $storeId to priority $priority');
    
    await client
        .from('stores')
        .update({'priority': priority})
        .eq('id', storeId)
        .eq('user_id', user.id);
  }
  
  logDebug('Store reordering complete!');
});

// Provider to search stores by ingredient name (bilingual search)
final searchStoresByIngredientProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, ingredientName) async {
  if (ingredientName.trim().isEmpty) {
    return [];
  }
  
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to search stores');
  }
  
  final searchTerm = ingredientName.trim();
  
  // Step 1: Find ingredient IDs that match the search term (English names)
  final englishMatches = await client
      .from('ingredients')
      .select('id')
      .ilike('name', '%$searchTerm%');
  
  // Step 2: Find ingredient IDs that match the search term (Chinese aliases)
  final chineseMatches = await client
      .from('ingredient_terms')
      .select('ingredient_id')
      .eq('locale', 'zh')
      .ilike('term', '%$searchTerm%');
  
  // Combine all matching ingredient IDs
  final Set<String> matchingIngredientIds = {};
  for (final match in englishMatches) {
    matchingIngredientIds.add(match['id'] as String);
  }
  for (final match in chineseMatches) {
    matchingIngredientIds.add(match['ingredient_id'] as String);
  }
  
  if (matchingIngredientIds.isEmpty) {
    return [];
  }
  
  // Step 3: Find stores that have these ingredients
  final results = await client
      .from('store_items')
      .select('''
        store_id,
        stores!inner(
          id,
          name,
          priority
        )
      ''')
      .eq('stores.user_id', user.id)
      .inFilter('ingredient_id', matchingIngredientIds.toList());
  
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

// Provider to delete a store item
final deleteStoreItemProvider = FutureProvider.family<void, String>((ref, storeItemId) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to delete store items');
  }
  
  logDebug('Deleting store item: $storeItemId');
  
  // First verify that the store item belongs to a store owned by the current user
  final storeItem = await client
      .from('store_items')
      .select('''
        id,
        store_id,
        stores!inner(
          id,
          user_id
        )
      ''')
      .eq('id', storeItemId)
      .eq('stores.user_id', user.id)
      .maybeSingle();
  
  if (storeItem == null) {
    throw Exception('Store item not found or does not belong to current user');
  }
  
  // Delete the store item
  await client
      .from('store_items')
      .delete()
      .eq('id', storeItemId);
  
  logDebug('Successfully deleted store item: $storeItemId');
});

// Provider to check if an ingredient matches a search term (bilingual)
final ingredientMatchesSearchProvider = FutureProvider.family<bool, ({String ingredientName, String searchTerm})>((ref, args) async {
  if (args.searchTerm.trim().isEmpty) {
    return false;
  }
  
  final client = SupabaseService.client;
  final searchTerm = args.searchTerm.trim().toLowerCase();
  final ingredientName = args.ingredientName.toLowerCase();
  
  // First check direct English name match
  if (ingredientName.contains(searchTerm)) {
    return true;
  }
  
  // Then check if the ingredient has Chinese aliases that match
  final ingredientResponse = await client
      .from('ingredients')
      .select('id')
      .eq('name', args.ingredientName)
      .maybeSingle();
  
  if (ingredientResponse == null) {
    return false;
  }
  
  final ingredientId = ingredientResponse['id'] as String;
  
  // Check Chinese aliases
  final chineseMatches = await client
      .from('ingredient_terms')
      .select('term')
      .eq('ingredient_id', ingredientId)
      .eq('locale', 'zh')
      .ilike('term', '%$searchTerm%');
  
  return chineseMatches.isNotEmpty;
});
