import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moduels.dart';
import '../services/supabase_service.dart';
import 'auth_providers.dart';
import '../utils/logger.dart';

// Add a refresh trigger for home inventory
final homeInventoryRefreshProvider = StateProvider<int>((ref) => 0);

final homeInventoryStreamProvider = StreamProvider<List<HomeInventoryItem>>((ref) {
  // Watch the refresh trigger to force refresh when needed
  ref.watch(homeInventoryRefreshProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    logDebug('No user found, returning empty home inventory list');
    return Stream.value(<HomeInventoryItem>[]);
  }

  logDebug('Fetching home inventory for user: ${user.id}');
  
  return SupabaseService.client
      .from('home_inventory')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('ingredient_name', ascending: true)
      .map((rows) {
        logDebug('Raw home inventory data for user ${user.id}: $rows');
        
        final items = rows.map((row) => HomeInventoryItem.fromMap(row)).toList();
        logDebug('Processed ${items.length} home inventory items for user ${user.id}');
        return items;
      });
});

// Provider to add a home inventory item
final addHomeInventoryItemProvider = FutureProvider.family<void, ({String ingredientName, String? unit, double? quantity})>((ref, args) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to add home inventory items');
  }
  
  logDebug('Adding home inventory item: ${args.ingredientName}');
  
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
  
  // Add the home inventory item
  await client.from('home_inventory').insert({
    'user_id': user.id,
    'ingredient_id': ingredientId,
    'ingredient_name': args.ingredientName,
    'unit': args.unit,
    'quantity': args.quantity,
  });
  
  logDebug('Successfully added home inventory item');
});

// Provider to delete a home inventory item
final deleteHomeInventoryItemProvider = FutureProvider.family<void, String>((ref, homeInventoryItemId) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to delete home inventory items');
  }
  
  logDebug('Deleting home inventory item: $homeInventoryItemId');
  
  // Verify that the item belongs to the current user
  final item = await client
      .from('home_inventory')
      .select('id, user_id')
      .eq('id', homeInventoryItemId)
      .eq('user_id', user.id)
      .maybeSingle();
  
  if (item == null) {
    throw Exception('Home inventory item not found or does not belong to current user');
  }
  
  // Delete the item
  await client
      .from('home_inventory')
      .delete()
      .eq('id', homeInventoryItemId);
  
  logDebug('Successfully deleted home inventory item: $homeInventoryItemId');
});

// Provider to get home inventory ingredient names (for meal planning)
final homeInventoryIngredientNamesProvider = FutureProvider<List<String>>((ref) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    return [];
  }
  
  final items = await client
      .from('home_inventory')
      .select('ingredient_name')
      .eq('user_id', user.id);
  
  return items.map((item) => item['ingredient_name'] as String).toList();
});
