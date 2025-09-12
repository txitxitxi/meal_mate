import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moduels.dart';
import '../services/supabase_service.dart';

final weeklyPlanProvider = StreamProvider<List<WeeklyEntry>>((ref) async* {
  final stream = SupabaseService.client
      .from('weekly_plans')
      .stream(primaryKey: ['id'])
      .order('week_start_date')
      .map((rows) async {
        final entries = <WeeklyEntry>[];
        final client = SupabaseService.client;
        
        for (final plan in rows) {
          final weekStart = DateTime.parse(plan['week_start_date'] as String);
          final planData = plan['plan'] as Map<String, dynamic>?;
          
          if (planData != null) {
            // Get all unique recipe IDs from the plan
            final recipeIds = planData.values.whereType<String>().toList();
            
            // Fetch all recipes in one query
            final recipes = <String, Map<String, dynamic>>{};
            if (recipeIds.isNotEmpty) {
              final recipeResponse = await client
                  .from('recipes')
                  .select('id, title, image_url')
                  .inFilter('id', recipeIds);
              
              for (final recipe in recipeResponse) {
                recipes[recipe['id'] as String] = recipe;
              }
            }
            
            // Parse the plan JSON to extract daily recipes
            for (int i = 0; i < 7; i++) {
              final day = weekStart.add(Duration(days: i));
              final dayKey = day.toIso8601String().split('T')[0]; // YYYY-MM-DD format
              final recipeId = planData[dayKey] as String?;
              
              if (recipeId != null) {
                final recipeData = recipes[recipeId];
                entries.add(WeeklyEntry(
                  day: day,
                  recipe: Recipe(
                    id: recipeId,
                    title: recipeData?['title'] as String? ?? 'Unknown Recipe',
                    imageUrl: recipeData?['image_url'] as String?,
                  ),
                ));
              }
            }
          }
        }
        return entries;
      }).asyncMap((future) => future);
  yield* stream;
});

final generatePlanProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, config) async {
  final proteinPreferences = config['proteinPreferences'] as List<String>;
  final uniqueRecipeTypes = config['uniqueRecipeTypes'] as int? ?? 3;
  final totalDays = config['totalDays'] as int? ?? 7;
  final mealsPerDay = config['mealsPerDay'] as int? ?? 1;
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to generate plans');
  }
  
  try {
    // Try to call the RPC function if it exists
    await client.rpc('generate_weekly_plan');
  } catch (_) {
    // Fallback: create a protein-aware weekly plan using ingredient categories
    // First, get all recipes for the user
    final allRecipes = await client
        .from('recipes')
        .select('id, title, image_url')
        .eq('user_id', user.id);

    if (allRecipes.isEmpty) {
      throw Exception('No recipes found. Please add some recipes first.');
    }

    // Get all recipe ingredients with their names
    final recipeIngredients = await client
        .from('recipe_ingredients')
        .select('recipe_id, ingredients!inner(name)')
        .inFilter('recipe_id', allRecipes.map((r) => r['id'] as String).toList());

    // Group ingredient names by recipe
    final recipeIngredientMap = <String, List<String>>{};
    for (final ri in recipeIngredients) {
      final recipeId = ri['recipe_id'] as String;
      final ingredientName = ri['ingredients']?['name'] as String?;
      if (ingredientName != null) {
        recipeIngredientMap.putIfAbsent(recipeId, () => []).add(ingredientName.toLowerCase());
      }
    }

    // Map UI protein preferences to specific ingredient name patterns
    final proteinPreferenceToPatterns = {
      'chicken': ['chicken', 'turkey', 'duck'],
      'beef': ['beef', 'steak', 'ground beef'],
      'pork': ['pork', 'bacon', 'ham'],
      'fish': ['salmon', 'tuna', 'cod', 'fish'],
      'seafood': ['shrimp', 'crab', 'lobster', 'scallop'],
      'vegetarian': ['bean', 'lentil', 'chickpea', 'tofu', 'cheese', 'milk', 'yogurt', 'almond', 'walnut'],
      'vegan': ['bean', 'lentil', 'chickpea', 'tofu', 'almond', 'walnut'],
    };
    
    // Get all relevant ingredient name patterns for the selected preferences
    final relevantPatterns = <String>[];
    for (final preference in proteinPreferences) {
      if (preference == 'none') {
        // If 'none' is selected, include all patterns
        relevantPatterns.addAll([
          'chicken', 'turkey', 'duck', 'beef', 'steak', 'pork', 'bacon', 'ham',
          'salmon', 'tuna', 'cod', 'fish', 'shrimp', 'crab', 'lobster',
          'bean', 'lentil', 'chickpea', 'tofu', 'cheese', 'milk', 'yogurt', 'almond', 'walnut'
        ]);
        break;
      } else if (proteinPreferenceToPatterns.containsKey(preference)) {
        relevantPatterns.addAll(proteinPreferenceToPatterns[preference]!);
      }
    }
    
    // Filter recipes by protein preferences based on ingredient names
    final filteredRecipes = allRecipes.where((recipe) {
      final recipeId = recipe['id'] as String;
      final ingredientNames = recipeIngredientMap[recipeId] ?? [];
      
      // Debug: Print recipe and its ingredient names
      print('Recipe: ${recipe['title']}');
      print('Ingredient names: $ingredientNames');
      print('Protein preferences: $proteinPreferences');
      print('Relevant patterns: $relevantPatterns');
      
      // Check if recipe has any ingredient names that match preferences
      final hasMatchingProtein = ingredientNames.any((ingredientName) {
        return relevantPatterns.any((pattern) => ingredientName.contains(pattern));
      });
      
      print('Has matching protein: $hasMatchingProtein');
      print('---');
      
      return hasMatchingProtein;
    }).toList();

    // If no recipes match protein preferences, use all recipes
    final recipesToUse = filteredRecipes.isNotEmpty ? filteredRecipes : allRecipes;
    
    print('Filtered recipes count: ${filteredRecipes.length}');
    print('Total recipes count: ${allRecipes.length}');
    print('Using recipes count: ${recipesToUse.length}');

    // Get the start of this week (Monday)
    final today = DateTime.now();
    final daysFromMonday = today.weekday - 1;
    final weekStart = today.subtract(Duration(days: daysFromMonday));
    
    // Select unique recipes based on configuration and store optimization
    final selectedRecipes = await _selectOptimalRecipes(client, recipesToUse, uniqueRecipeTypes);
    final totalMeals = totalDays * mealsPerDay;
    
    print('Configuration: $uniqueRecipeTypes unique types, $totalDays days, $mealsPerDay meals/day = $totalMeals total meals');
    print('Selected recipes: ${selectedRecipes.map((r) => r['title']).toList()}');
    
    // Create plan data with configuration-aware selection
    final planData = <String, String>{};
    for (int day = 0; day < totalDays; day++) {
      final dayDate = weekStart.add(Duration(days: day));
      final dayStr = dayDate.toIso8601String().split('T')[0];
      
      for (int meal = 0; meal < mealsPerDay; meal++) {
        // Cycle through selected recipes
        final recipeIndex = (day * mealsPerDay + meal) % selectedRecipes.length;
        final recipe = selectedRecipes[recipeIndex];
        
        // For multiple meals per day, use day_meal format
        final mealKey = mealsPerDay > 1 ? '${dayStr}_$meal' : dayStr;
        planData[mealKey] = recipe['id'] as String;
      }
    }
    
    print('Generated plan with ${planData.length} meal slots using ${selectedRecipes.length} unique recipes');

    // Insert or update the weekly plan
    final weeklyPlanResponse = await client.from('weekly_plans').upsert({
      'user_id': user.id,
      'week_start_date': weekStart.toIso8601String().split('T')[0],
      'protein_priority': proteinPreferences,
      'plan': planData,
    }, onConflict: 'user_id,week_start_date').select('id').single();
    
    final weeklyPlanId = weeklyPlanResponse['id'] as String;
    print('Weekly plan created successfully! Auto-generating shopping list...');
    
    // Auto-generate shopping list after creating weekly plan
    try {
      await _generateShoppingListFromPlan(client, user.id, weeklyPlanId, planData);
      print('Shopping list auto-generated successfully!');
    } catch (e) {
      print('Failed to auto-generate shopping list: $e');
      // Don't throw here - weekly plan was created successfully
    }
  }
});

final shoppingListProvider = StreamProvider<List<ShoppingListItem>>((ref) {
  return SupabaseService.client
      .from('shopping_list_items')
      .stream(primaryKey: ['id'])
      .order('id', ascending: true)
      .map((rows) async {
        // Get all unique store IDs and ingredient IDs
        final storeIds = rows.map((r) => r['store_id'] as String?).whereType<String>().toSet().toList();
        final ingredientIds = rows.map((r) => r['ingredient_id'] as String).toSet().toList();
        
        // Batch fetch store names and ingredient names
        final stores = <String, String>{};
        if (storeIds.isNotEmpty) {
          final storeResponse = await SupabaseService.client
              .from('stores')
              .select('id, name')
              .inFilter('id', storeIds);
          for (final store in storeResponse) {
            stores[store['id'] as String] = store['name'] as String;
          }
        }
        
        final ingredients = <String, String>{};
        if (ingredientIds.isNotEmpty) {
          final ingredientResponse = await SupabaseService.client
              .from('ingredients')
              .select('id, name')
              .inFilter('id', ingredientIds);
          for (final ingredient in ingredientResponse) {
            ingredients[ingredient['id'] as String] = ingredient['name'] as String;
          }
        }
        
        // Create shopping list items
        final items = <ShoppingListItem>[];
        for (final row in rows) {
          final storeId = row['store_id'] as String?;
          final ingredientId = row['ingredient_id'] as String;
          
          items.add(ShoppingListItem(
            id: row['id'] as String,
            ingredientName: ingredients[ingredientId] ?? 'Unknown',
            storeId: storeId,
            storeName: storeId != null ? stores[storeId] : null,
            unit: row['unit'] as String?,
            qty: (row['quantity'] as num?)?.toDouble(),
            purchased: (row['is_checked'] as bool?) ?? false,
          ));
        }
        return items;
      }).asyncMap((future) => future);
});

final togglePurchasedProvider = FutureProvider.family<void, String>((ref, itemId) async {
  final client = SupabaseService.client;
  final current = await client.from('shopping_list_items').select('is_checked').eq('id', itemId).single();
  final next = !(current['is_checked'] as bool? ?? false);
  await client.from('shopping_list_items').update({'is_checked': next}).eq('id', itemId);
});

final generateShoppingListProvider = FutureProvider<void>((ref) async {
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to generate shopping list');
  }
  
  // Get the current weekly plan
  final weeklyPlans = await client
      .from('weekly_plans')
      .select('id, plan')
      .eq('user_id', user.id)
      .order('week_start_date', ascending: false)
      .limit(1);
  
  print('Weekly plans found: ${weeklyPlans.length}');
  print('Weekly plans data: $weeklyPlans');
  
  if (weeklyPlans.isEmpty) {
    throw Exception('No weekly plan found. Please generate a weekly plan first.');
  }
  
  final weeklyPlanId = weeklyPlans.first['id'] as String?;
  final planData = weeklyPlans.first['plan'] as Map<String, dynamic>?;
  
  if (weeklyPlanId == null) {
    throw Exception('Weekly plan ID is missing.');
  }
  
  if (planData == null) {
    throw Exception('Weekly plan is empty.');
  }
  
  // Get all recipe IDs from the plan and count occurrences
  final recipeCounts = <String, int>{};
  for (final recipeId in planData.values.whereType<String>()) {
    recipeCounts[recipeId] = (recipeCounts[recipeId] ?? 0) + 1;
  }
  
  final recipeIds = recipeCounts.keys.toList();
  if (recipeIds.isEmpty) {
    throw Exception('No recipes found in weekly plan.');
  }
  
  print('Plan data: $planData');
  print('Recipe counts: $recipeCounts');
  print('Recipe IDs: $recipeIds');
  
  // Get all ingredients for these recipes
  final recipeIngredients = await client
      .from('recipe_ingredients')
      .select('recipe_id, ingredient_id, quantity, unit, ingredients!inner(name)')
      .inFilter('recipe_id', recipeIds);
  
  print('Recipe IDs: $recipeIds');
  print('Recipe ingredients count: ${recipeIngredients.length}');
  
  // Group ingredients by name and sum quantities (multiplied by meal count)
  final ingredientMap = <String, Map<String, dynamic>>{};
  for (final ri in recipeIngredients) {
    try {
      final recipeId = ri['recipe_id'] as String?;
      if (recipeId == null) {
        print('Warning: recipe_id is null for ingredient: $ri');
        continue;
      }
      
      final mealCount = recipeCounts[recipeId] ?? 1;
      final ingredientName = ri['ingredients']?['name'] as String? ?? 'Unknown';
      final quantity = (ri['quantity'] as num? ?? 0) * mealCount; // Multiply by meal count
      final unit = ri['unit'] as String? ?? 'unit';
      
      print('Processing ingredient: $ingredientName, qty: $quantity, unit: $unit (x$mealCount meals)');
      
      if (ingredientMap.containsKey(ingredientName)) {
        // Sum quantities for the same ingredient
        final existing = ingredientMap[ingredientName]!;
        final existingQty = existing['quantity'] as num? ?? 0;
        ingredientMap[ingredientName] = {
          'name': ingredientName,
          'quantity': existingQty + quantity,
          'unit': unit,
        };
      } else {
        ingredientMap[ingredientName] = {
          'name': ingredientName,
          'quantity': quantity,
          'unit': unit,
        };
      }
    } catch (e) {
      print('Error processing ingredient: $e');
      print('Raw ingredient data: $ri');
    }
  }
  
  // Clear existing shopping list items
  await client.from('shopping_list_items').delete().eq('weekly_plan_id', weeklyPlanId);
  
  // Get stores and their items to categorize ingredients
  final stores = await client
      .from('stores')
      .select('id, name, is_default')
      .eq('user_id', user.id)
      .order('is_default', ascending: false)
      .order('priority');
  
  final storeItems = await client
      .from('store_items')
      .select('store_id, ingredient_id, ingredients!inner(name)');
  
  print('Store items found: ${storeItems.length}');
  print('Store items data: $storeItems');
  
  // Debug: Check which stores have beef
  final beefStores = storeItems.where((item) => 
    (item['ingredients']?['name'] as String?)?.toLowerCase() == 'beef').toList();
  print('Beef availability: ${beefStores.map((item) => {
    'store_id': item['store_id'],
    'store_name': stores.firstWhere((s) => s['id'] == item['store_id'], orElse: () => {'name': 'Unknown'})['name']
  }).toList()}');
  
  // Create ingredient to store mapping
  final ingredientToStore = <String, String>{};
  for (final storeItem in storeItems) {
    final ingredientName = storeItem['ingredients']?['name'] as String?;
    final storeId = storeItem['store_id'] as String;
    if (ingredientName != null) {
      ingredientToStore[ingredientName] = storeId;
      print('Mapped ingredient: $ingredientName -> store: $storeId');
    }
  }
  
  print('Total ingredient mappings: ${ingredientToStore.length}');
  print('Ingredient mappings: $ingredientToStore');
  
  // Group ingredients by store
  final storeIngredientMap = <String, List<Map<String, dynamic>>>{};
  for (final ingredient in ingredientMap.values) {
    final ingredientName = ingredient['name'] as String;
    final storeId = ingredientToStore[ingredientName];
    
    print('Ingredient: $ingredientName -> Store ID: $storeId');
    
    if (storeId != null) {
      storeIngredientMap.putIfAbsent(storeId, () => []).add(ingredient);
    } else {
      // If no store found, put in "No Store"
      storeIngredientMap.putIfAbsent('no_store', () => []).add(ingredient);
    }
  }
  
  print('Store ingredient mapping: ${storeIngredientMap.keys.toList()}');
  print('Total ingredients to process: ${ingredientMap.length}');
  
  // Create store ID to name mapping
  final storeIdToName = <String, String>{};
  for (final store in stores) {
    storeIdToName[store['id'] as String] = store['name'] as String;
  }
  
  // Insert shopping list items grouped by store
  for (final storeEntry in storeIngredientMap.entries) {
    final storeId = storeEntry.key == 'no_store' ? null : storeEntry.key;
    final ingredients = storeEntry.value;
    final storeName = storeId != null ? storeIdToName[storeId] : 'No Store';
    
    print('Processing store: ${storeEntry.key} -> $storeName (${ingredients.length} ingredients)');
    
    for (final ingredient in ingredients) {
      // Find or create ingredient
      final ingredientResponse = await client
          .from('ingredients')
          .select('id')
          .eq('name', ingredient['name'])
          .maybeSingle();
      
      String ingredientId;
      if (ingredientResponse != null) {
        ingredientId = ingredientResponse['id'] as String;
      } else {
        // Create new ingredient
        final newIngredient = await client
            .from('ingredients')
            .insert({'name': ingredient['name']})
            .select('id')
            .single();
        ingredientId = newIngredient['id'] as String;
      }
      
      // Insert shopping list item
      await client.from('shopping_list_items').insert({
        'weekly_plan_id': weeklyPlanId,
        'ingredient_id': ingredientId,
        'store_id': storeId,
        'quantity': ingredient['quantity'],
        'unit': ingredient['unit'],
        'is_checked': false,
      });
    }
  }
  
  print('Shopping list generation completed successfully!');
  print('Total ingredients processed: ${ingredientMap.length}');
});

// Helper function to generate shopping list from plan data
Future<void> _generateShoppingListFromPlan(
  dynamic client, 
  String userId, 
  String weeklyPlanId, 
  Map<String, dynamic> planData
) async {
  // Get all recipe IDs from the plan and count occurrences
  final recipeCounts = <String, int>{};
  for (final recipeId in planData.values.whereType<String>()) {
    recipeCounts[recipeId] = (recipeCounts[recipeId] ?? 0) + 1;
  }
  
  final recipeIds = recipeCounts.keys.toList();
  if (recipeIds.isEmpty) {
    throw Exception('No recipes found in weekly plan.');
  }
  
  print('Auto-generating shopping list for ${recipeIds.length} recipes');
  
  // Get all ingredients for these recipes
  final recipeIngredients = await client
      .from('recipe_ingredients')
      .select('recipe_id, ingredient_id, quantity, unit, ingredients!inner(name)')
      .inFilter('recipe_id', recipeIds);
  
  // Group ingredients by name and sum quantities (multiplied by meal count)
  final ingredientMap = <String, Map<String, dynamic>>{};
  for (final ri in recipeIngredients) {
    try {
      final recipeId = ri['recipe_id'] as String?;
      if (recipeId == null) {
        print('Warning: recipe_id is null for ingredient: $ri');
        continue;
      }
      
      final mealCount = recipeCounts[recipeId] ?? 1;
      final ingredientName = ri['ingredients']?['name'] as String? ?? 'Unknown';
      final quantity = (ri['quantity'] as num? ?? 0) * mealCount;
      final unit = ri['unit'] as String? ?? 'unit';
      
      if (ingredientMap.containsKey(ingredientName)) {
        final existing = ingredientMap[ingredientName]!;
        final existingQty = existing['quantity'] as num? ?? 0;
        ingredientMap[ingredientName] = {
          'name': ingredientName,
          'quantity': existingQty + quantity,
          'unit': unit,
        };
      } else {
        ingredientMap[ingredientName] = {
          'name': ingredientName,
          'quantity': quantity,
          'unit': unit,
        };
      }
    } catch (e) {
      print('Error processing ingredient: $e');
    }
  }
  
  // Clear existing shopping list items
  await client.from('shopping_list_items').delete().eq('weekly_plan_id', weeklyPlanId);
  
  // Get stores and their items to categorize ingredients
  final storeItems = await client
      .from('store_items')
      .select('store_id, ingredient_id, ingredients!inner(name)');
  
  // Get store priorities for ingredient assignment
  final stores = await client
      .from('stores')
      .select('id, name, priority, is_default')
      .order('priority', ascending: true);
  
  final storePriorities = <String, int>{};
  for (final store in stores) {
    final storeId = store['id'] as String;
    final priority = store['priority'] as int? ?? 10;
    final name = store['name'] as String;
    final isDefault = store['is_default'] as bool? ?? false;
    storePriorities[storeId] = priority;
    print('Store: $name (ID: $storeId, Priority: $priority, Default: $isDefault)');
  }
  
  // Create ingredient to store mapping with priority-based selection
  final ingredientToStore = <String, String>{};
  final ingredientStoreOptions = <String, List<String>>{};
  
  // First, collect all stores that have each ingredient
  for (final storeItem in storeItems) {
    final ingredientName = storeItem['ingredients']?['name'] as String?;
    final storeId = storeItem['store_id'] as String;
    if (ingredientName != null) {
      ingredientStoreOptions.putIfAbsent(ingredientName, () => []).add(storeId);
    }
  }
  
  // Then, for each ingredient, choose the highest priority store
  for (final entry in ingredientStoreOptions.entries) {
    final ingredientName = entry.key;
    final availableStores = entry.value;
    
    // Sort stores by priority (lower number = higher priority), then by default status
    availableStores.sort((a, b) {
      final priorityA = storePriorities[a] ?? 10;
      final priorityB = storePriorities[b] ?? 10;
      
      // First priority: higher priority stores (lower number)
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      // Second priority: default stores when priorities are equal
      final isDefaultA = stores.firstWhere((s) => s['id'] == a)['is_default'] as bool? ?? false;
      final isDefaultB = stores.firstWhere((s) => s['id'] == b)['is_default'] as bool? ?? false;
      
      if (isDefaultA && !isDefaultB) return -1;
      if (!isDefaultA && isDefaultB) return 1;
      return 0; // Both have same priority and default status
    });
    
    // Assign to the highest priority store
    final selectedStoreId = availableStores.first;
    ingredientToStore[ingredientName] = selectedStoreId;
    
    if (ingredientName.toLowerCase() == 'beef') {
      final selectedStoreName = stores.firstWhere((s) => s['id'] == selectedStoreId)['name'];
      final selectedStorePriority = storePriorities[selectedStoreId] ?? 10;
      final selectedStoreIsDefault = stores.firstWhere((s) => s['id'] == selectedStoreId)['is_default'] as bool? ?? false;
      print('Beef assigned to: $selectedStoreName (Priority: $selectedStorePriority, Default: $selectedStoreIsDefault)');
      print('Available stores for beef: ${availableStores.map((id) => {
        'name': stores.firstWhere((s) => s['id'] == id)['name'],
        'priority': storePriorities[id] ?? 10,
        'is_default': stores.firstWhere((s) => s['id'] == id)['is_default'] as bool? ?? false
      }).toList()}');
    }
  }
  
  print('Ingredient-to-store assignment (priority-based):');
  for (final entry in ingredientToStore.entries) {
    final storeName = stores.firstWhere((s) => s['id'] == entry.value, orElse: () => {'name': 'Unknown'})['name'];
    final priority = storePriorities[entry.value] ?? 10;
    print('  ${entry.key} → $storeName (Priority: $priority)');
  }
  
  // Optimize store visits by consolidating ingredients
  final storeIngredientMap = <String, List<Map<String, dynamic>>>{};
  final unassignedIngredients = <Map<String, dynamic>>[];
  
  // First pass: assign ingredients to stores where they're available
  for (final ingredient in ingredientMap.values) {
    final ingredientName = ingredient['name'] as String;
    final storeId = ingredientToStore[ingredientName];
    
    if (storeId != null) {
      storeIngredientMap.putIfAbsent(storeId, () => []).add(ingredient);
      print('Initial assignment: $ingredientName → ${stores.firstWhere((s) => s['id'] == storeId)['name']}');
    } else {
      unassignedIngredients.add(ingredient);
    }
  }
  
  print('Before optimization: ${storeIngredientMap.map((k, v) => MapEntry(stores.firstWhere((s) => s['id'] == k)['name'], v.length))}');
  
  // Second pass: optimize by consolidating ingredients to minimize store visits
  await _optimizeStoreVisits(client, storeIngredientMap, unassignedIngredients);
  
  print('After optimization: ${storeIngredientMap.map((k, v) => MapEntry(stores.firstWhere((s) => s['id'] == k)['name'], v.length))}');
  
  // Insert shopping list items grouped by store
  for (final storeEntry in storeIngredientMap.entries) {
    final storeId = storeEntry.key == 'no_store' ? null : storeEntry.key;
    final ingredients = storeEntry.value;
    
    for (final ingredient in ingredients) {
      // Find or create ingredient
      final ingredientResponse = await client
          .from('ingredients')
          .select('id')
          .eq('name', ingredient['name'])
          .maybeSingle();
      
      String ingredientId;
      if (ingredientResponse != null) {
        ingredientId = ingredientResponse['id'] as String;
      } else {
        final newIngredient = await client
            .from('ingredients')
            .insert({'name': ingredient['name']})
            .select('id')
            .single();
        ingredientId = newIngredient['id'] as String;
      }
      
      // Insert shopping list item
      await client.from('shopping_list_items').insert({
        'weekly_plan_id': weeklyPlanId,
        'ingredient_id': ingredientId,
        'store_id': storeId,
        'quantity': ingredient['quantity'],
        'unit': ingredient['unit'],
        'is_checked': false,
      });
    }
  }
  
  print('Auto-generated shopping list with ${ingredientMap.length} ingredients');
}

// Helper function to select optimal recipes that minimize store visits
Future<List<Map<String, dynamic>>> _selectOptimalRecipes(
  dynamic client,
  List<Map<String, dynamic>> availableRecipes,
  int uniqueRecipeTypes,
) async {
  if (availableRecipes.isEmpty) return [];
  
  print('Selecting optimal recipes to minimize store visits...');
  
  // Get store priorities
  final stores = await client
      .from('stores')
      .select('id, name, priority, is_default')
      .order('priority', ascending: true);
  
  final storePriorities = <String, int>{};
  for (final store in stores) {
    storePriorities[store['id'] as String] = store['priority'] as int? ?? 10;
  }
  
  // Get all store items to understand ingredient availability
  final storeItems = await client
      .from('store_items')
      .select('store_id, ingredients!inner(name)');
  
  final ingredientToStores = <String, List<String>>{};
  for (final storeItem in storeItems) {
    final ingredientName = storeItem['ingredients']?['name'] as String?;
    final storeId = storeItem['store_id'] as String;
    if (ingredientName != null) {
      ingredientToStores.putIfAbsent(ingredientName, () => []).add(storeId);
    }
  }
  
  // Get ingredients for each recipe
  final recipeScores = <Map<String, dynamic>, double>{};
  
  for (final recipe in availableRecipes) {
    final recipeId = recipe['id'] as String;
    
    // Get ingredients for this recipe
    final recipeIngredients = await client
        .from('recipe_ingredients')
        .select('ingredients!inner(name)')
        .eq('recipe_id', recipeId);
    
    double score = 0;
    int totalIngredients = 0;
    final storeUsage = <String, int>{};
    
    for (final ri in recipeIngredients) {
      final ingredientName = ri['ingredients']?['name'] as String?;
      if (ingredientName != null) {
        totalIngredients++;
        final availableStores = ingredientToStores[ingredientName] ?? [];
        
        if (availableStores.isNotEmpty) {
          // Find the highest priority store that has this ingredient
          availableStores.sort((a, b) {
            final priorityA = storePriorities[a] ?? 10;
            final priorityB = storePriorities[b] ?? 10;
            return priorityA.compareTo(priorityB);
          });
          
          final bestStore = availableStores.first;
          storeUsage[bestStore] = (storeUsage[bestStore] ?? 0) + 1;
          
          // Score based on store priority (lower number = higher priority = better score)
          final priority = storePriorities[bestStore] ?? 10;
          score += (11 - priority); // Invert priority so higher priority = higher score
        } else {
          // Penalty for ingredients not available at any store
          score -= 5;
        }
      }
    }
    
    if (totalIngredients > 0) {
      // Bonus for recipes that use fewer unique stores
      final uniqueStores = storeUsage.keys.length;
      final consolidationBonus = totalIngredients / uniqueStores; // Higher is better
      score += consolidationBonus * 2;
      
      // Penalty for recipes that require many stores
      if (uniqueStores > 2) {
        score -= (uniqueStores - 2) * 3;
      }
    }
    
    recipeScores[recipe] = score;
    print('Recipe "${recipe['title']}": score=$score, stores=${storeUsage.keys.length}, ingredients=$totalIngredients');
  }
  
  // Sort recipes by score (highest first) and take the top ones
  final sortedRecipes = recipeScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  final selectedRecipes = sortedRecipes
      .take(uniqueRecipeTypes)
      .map((entry) => entry.key)
      .toList();
  
  print('Selected optimal recipes: ${selectedRecipes.map((r) => '${r['title']} (score: ${recipeScores[r]?.toStringAsFixed(1)})').join(', ')}');
  
  return selectedRecipes;
}

// Helper function to optimize store visits by consolidating ingredients
Future<void> _optimizeStoreVisits(
  dynamic client,
  Map<String, List<Map<String, dynamic>>> storeIngredientMap,
  List<Map<String, dynamic>> unassignedIngredients,
) async {
  print('Optimizing store visits...');
  
  // Get all stores with their priority and preferred status
  final stores = await client
      .from('stores')
      .select('id, name, priority, is_default')
      .order('priority', ascending: true);
  
  // Create store priority map (lower number = higher priority)
  final storePriorities = <String, int>{};
  final defaultStoreId = <String>{};
  
  for (final store in stores) {
    final storeId = store['id'] as String;
    final priority = store['priority'] as int? ?? 10;
    final isDefault = store['is_default'] as bool? ?? false;
    
    storePriorities[storeId] = priority;
    if (isDefault) {
      defaultStoreId.add(storeId);
    }
  }
  
  // Strategy 1: Prioritize minimizing store visits, then use store priority as tiebreaker
  final storeSizes = <String, int>{};
  for (final entry in storeIngredientMap.entries) {
    storeSizes[entry.key] = entry.value.length;
  }
  
  // Sort stores by priority first (lower number = higher priority), then by default status, then by size
  final sortedStores = storeIngredientMap.keys.toList()
    ..sort((a, b) {
      final priorityA = storePriorities[a] ?? 10;
      final priorityB = storePriorities[b] ?? 10;
      final sizeA = storeSizes[a] ?? 0;
      final sizeB = storeSizes[b] ?? 0;
      final isDefaultA = defaultStoreId.contains(a);
      final isDefaultB = defaultStoreId.contains(b);
      
      // First priority: higher priority stores (lower number)
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      // Second priority: default stores when priorities are equal
      if (isDefaultA && !isDefaultB) return -1;
      if (!isDefaultA && isDefaultB) return 1;
      // Third priority: larger stores (for better consolidation)
      return sizeB.compareTo(sizeA);
    });
  
  print('Store optimization order (by priority): ${sortedStores.map((id) => '${stores.firstWhere((s) => s['id'] == id)['name']} (Priority: ${storePriorities[id]}, ${storeSizes[id]} items)').join(', ')}');
  
  // Strategy 2: For ingredients available in multiple stores, choose the store with most other ingredients
  final ingredientAvailability = <String, List<String>>{};
  final storeItems = await client
      .from('store_items')
      .select('store_id, ingredients!inner(name)');
  
  for (final storeItem in storeItems) {
    final ingredientName = storeItem['ingredients']?['name'] as String?;
    final storeId = storeItem['store_id'] as String;
    if (ingredientName != null) {
      ingredientAvailability.putIfAbsent(ingredientName, () => []).add(storeId);
    }
  }
  
  // Reassign ingredients to optimize store consolidation with priority-based approach
  final optimizedStoreMap = <String, List<Map<String, dynamic>>>{};
  final processedIngredients = <String>{};
  
  // Start with the highest priority store as the primary consolidation target
  final primaryStore = sortedStores.isNotEmpty ? sortedStores.first : null;
  
  if (primaryStore != null) {
    print('Primary consolidation target: ${stores.firstWhere((s) => s['id'] == primaryStore)['name']} (Priority: ${storePriorities[primaryStore]})');
    
    // First pass: Try to consolidate everything into the primary store
    optimizedStoreMap[primaryStore] = List.from(storeIngredientMap[primaryStore] ?? []);
    
    for (final sourceStoreId in storeIngredientMap.keys) {
      if (sourceStoreId == primaryStore) continue;
      
      final ingredientsToMove = <Map<String, dynamic>>[];
      final remainingIngredients = <Map<String, dynamic>>[];
      
      for (final ingredient in storeIngredientMap[sourceStoreId] ?? []) {
        final ingredientName = ingredient['name'] as String;
        if (processedIngredients.contains(ingredientName)) continue;
        
        final availableStores = ingredientAvailability[ingredientName] ?? [];
        if (availableStores.contains(primaryStore)) {
          // This ingredient is available at the primary store, move it
          ingredientsToMove.add(ingredient);
          processedIngredients.add(ingredientName);
        } else {
          remainingIngredients.add(ingredient);
        }
      }
      
      if (ingredientsToMove.isNotEmpty) {
        print('Moving ${ingredientsToMove.length} ingredients from ${stores.firstWhere((s) => s['id'] == sourceStoreId)['name']} to ${stores.firstWhere((s) => s['id'] == primaryStore)['name']}');
        optimizedStoreMap[primaryStore]!.addAll(ingredientsToMove);
      }
      
      // Only keep stores that have ingredients not available at primary store
      if (remainingIngredients.isNotEmpty) {
        optimizedStoreMap[sourceStoreId] = remainingIngredients;
      }
    }
  }
  
  // Second pass: For remaining stores, consolidate into the next highest priority stores
  final remainingStores = optimizedStoreMap.keys.where((id) => id != primaryStore).toList();
  remainingStores.sort((a, b) {
    final priorityA = storePriorities[a] ?? 10;
    final priorityB = storePriorities[b] ?? 10;
    return priorityA.compareTo(priorityB);
  });
  
  for (int i = 0; i < remainingStores.length; i++) {
    final targetStoreId = remainingStores[i];
    
    for (int j = i + 1; j < remainingStores.length; j++) {
      final sourceStoreId = remainingStores[j];
      
      final ingredientsToMove = <Map<String, dynamic>>[];
      final remainingIngredients = <Map<String, dynamic>>[];
      
      for (final ingredient in optimizedStoreMap[sourceStoreId] ?? []) {
        final ingredientName = ingredient['name'] as String;
        if (processedIngredients.contains(ingredientName)) continue;
        
        final availableStores = ingredientAvailability[ingredientName] ?? [];
        if (availableStores.contains(targetStoreId)) {
          ingredientsToMove.add(ingredient);
          processedIngredients.add(ingredientName);
        } else {
          remainingIngredients.add(ingredient);
        }
      }
      
      if (ingredientsToMove.isNotEmpty) {
        print('Moving ${ingredientsToMove.length} ingredients from ${stores.firstWhere((s) => s['id'] == sourceStoreId)['name']} to ${stores.firstWhere((s) => s['id'] == targetStoreId)['name']}');
        optimizedStoreMap[targetStoreId]!.addAll(ingredientsToMove);
        
        if (remainingIngredients.isEmpty) {
          optimizedStoreMap.remove(sourceStoreId);
        } else {
          optimizedStoreMap[sourceStoreId] = remainingIngredients;
        }
      }
    }
  }
  
  // Handle remaining stores that weren't processed
  for (final storeId in storeIngredientMap.keys) {
    if (!optimizedStoreMap.containsKey(storeId)) {
      optimizedStoreMap[storeId] = storeIngredientMap[storeId] ?? [];
    }
  }
  
  // Assign unassigned ingredients to default store or highest priority store
  if (unassignedIngredients.isNotEmpty) {
    String targetStore;
    if (defaultStoreId.isNotEmpty) {
      targetStore = defaultStoreId.first;
    } else if (storePriorities.isNotEmpty) {
      targetStore = storePriorities.entries
          .reduce((a, b) => a.value < b.value ? a : b)
          .key;
    } else {
      targetStore = 'no_store';
    }
    
    optimizedStoreMap.putIfAbsent(targetStore, () => []).addAll(unassignedIngredients);
    print('Assigned ${unassignedIngredients.length} unassigned ingredients to ${targetStore == 'no_store' ? 'no specific store' : stores.firstWhere((s) => s['id'] == targetStore)['name']}');
  }
  
  // Update the store ingredient map
  storeIngredientMap.clear();
  storeIngredientMap.addAll(optimizedStoreMap);
  
  print('Final store consolidation:');
  for (final entry in storeIngredientMap.entries) {
    final storeName = entry.key == 'no_store' ? 'No specific store' : 
        stores.firstWhere((s) => s['id'] == entry.key, orElse: () => {'name': 'Unknown'})['name'];
    print('  $storeName: ${entry.value.map((i) => i['name']).join(', ')}');
  }
  
  // Print optimization results
  final totalStores = storeIngredientMap.keys.where((id) => id != 'no_store').length;
  print('Store optimization complete!');
  print('Total stores to visit: $totalStores');
  
  // Sort final results by priority for display
  final sortedFinalStores = storeIngredientMap.entries.toList()
    ..sort((a, b) {
      final priorityA = storePriorities[a.key] ?? 10;
      final priorityB = storePriorities[b.key] ?? 10;
      return priorityA.compareTo(priorityB);
    });
  
  for (final entry in sortedFinalStores) {
    final storeName = entry.key == 'no_store' ? 'No specific store' : 
        stores.firstWhere((s) => s['id'] == entry.key, orElse: () => {'name': 'Unknown'})['name'];
    final priority = storePriorities[entry.key] ?? 10;
    print('  - $storeName (Priority: $priority): ${entry.value.length} items');
  }
}
