// lib/providers/meal_plan_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moduels.dart';
import '../services/supabase_service.dart';
import '../utils/protein_preferences.dart';
import 'auth_providers.dart';
import '../utils/logger.dart';
// Add a refresh trigger for meal plans
final mealPlanRefreshProvider = StateProvider<int>((ref) => 0);

// Add a refresh trigger for shopping lists
final shoppingListRefreshProvider = StateProvider<int>((ref) => 0);

final mealPlanProvider = StreamProvider<List<MealPlanSummary>>((ref) async* {
  // Watch the refresh trigger to force refresh when needed
  final refreshTrigger = ref.watch(mealPlanRefreshProvider);
  logDebug('Meal plan provider triggered with refresh: $refreshTrigger');
  
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    logDebug('No user found, returning empty meal plan');
    yield <MealPlanSummary>[];
    return;
  }

  logDebug('Loading meal plan for user: ${user.id}');
  
  // Force a fresh query every time by adding the refresh trigger to the query
  final rows = await SupabaseService.client
      .from('meal_plans')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(1);
  
  logDebug('Found ${rows.length} weekly plans');
  if (rows.isNotEmpty) {
    final plan = rows.first;
    logDebug('Latest plan ID: ${plan['id']}');
    logDebug('Latest plan created_at: ${plan['created_at']}');
    logDebug('Latest plan week_start_date: ${plan['week_start_date']}');
    logDebug('LOADING PLAN WITH ID: ${plan['id']}');
  }
  
  final entries = <MealPlanSummary>[];
  
  if (rows.isNotEmpty) {
    final plan = rows.first;
    final planData = plan['plan'] as Map<String, dynamic>?;
    
    if (planData != null) {
      logDebug('Processing plan data: $planData');
      
      // Get all unique recipe IDs from the plan
      final recipeIds = planData.values.whereType<String>().toList();
      logDebug('Recipe IDs from plan: $recipeIds');
      
      // Fetch all recipes in one query
      final recipes = <String, Map<String, dynamic>>{};
      if (recipeIds.isNotEmpty) {
        final recipeResponse = await SupabaseService.client
            .from('recipes')
            .select('id, title, image_url')
            .inFilter('id', recipeIds);
        
        for (final recipe in recipeResponse) {
          recipes[recipe['id'] as String] = recipe;
        }
        logDebug('Fetched ${recipes.length} recipes');
      }
      
      // Count occurrences of each recipe
      final recipeCounts = <String, int>{};
      for (final recipeId in recipeIds) {
        recipeCounts[recipeId] = (recipeCounts[recipeId] ?? 0) + 1;
      }
      logDebug('Recipe counts: $recipeCounts');
      
      // Create entries for unique recipes with their counts
      for (final entry in recipeCounts.entries) {
        final recipeId = entry.key;
        final count = entry.value;
        final recipeData = recipes[recipeId];
        
        entries.add(MealPlanSummary(
          recipe: Recipe(
            id: recipeId,
            title: recipeData?['title'] as String? ?? 'Unknown Recipe',
            imageUrl: recipeData?['image_url'] as String?,
          ),
          count: count,
        ));
      }
    }
  }
  
  logDebug('Meal plan entries created: ${entries.length}');
  logDebug('Entries: ${entries.map((e) => e.recipe.title).toList()}');
  
  yield entries;
});

final generatePlanProvider = FutureProvider.family<String, Map<String, dynamic>>((ref, config) async {
  final proteinPreferences = config['proteinPreferences'] as List<String>;
  final uniqueRecipeTypes = config['uniqueRecipeTypes'] as int? ?? 3;
  final totalDays = config['totalDays'] as int? ?? 7;
  final mealsPerDay = config['mealsPerDay'] as int? ?? 1;
  final client = SupabaseService.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User must be signed in to generate plans');
  }
  
  // Get user's own recipes
  final userOwnRecipes = await client
      .from('recipes')
      .select('id, title, image_url')
      .eq('author_id', user.id);
  
  // Get user's saved recipes
  final savedRecipeIds = await client
      .from('recipe_saves')
      .select('recipe_id')
      .eq('user_id', user.id);
  
  List<Map<String, dynamic>> savedRecipes = [];
  if (savedRecipeIds.isNotEmpty) {
    savedRecipes = await client
        .from('recipes')
        .select('id, title, image_url')
        .inFilter('id', savedRecipeIds.map((s) => s['recipe_id'] as String).toList())
        .eq('visibility', 'public'); // Only load public recipes
  }
  
  // Combine user's own recipes and saved recipes, removing duplicates
  final recipeMap = <String, Map<String, dynamic>>{};
  for (final recipe in userOwnRecipes) {
    recipeMap[recipe['id'] as String] = recipe;
  }
  for (final recipe in savedRecipes) {
    recipeMap[recipe['id'] as String] = recipe;
  }
  final allRecipes = recipeMap.values.toList();

  if (allRecipes.isEmpty) {
    throw Exception('No recipes found. Please add some recipes first.');
  }
  
  logDebug('User own recipes: ${userOwnRecipes.length}');
  logDebug('Saved recipes: ${savedRecipes.length}');
  logDebug('Total unique recipes for meal planning: ${allRecipes.length}');
  logDebug('Recipe titles: ${allRecipes.map((r) => r['title']).toList()}');

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

    // Use centralized protein preference patterns
    final proteinPreferenceToPatterns = ProteinPreferences.ingredientPatterns;
    
    // Get all relevant ingredient name patterns for the selected preferences
    final relevantPatterns = <String>[];
    for (final preference in proteinPreferences) {
      if (preference == 'none') {
        // If 'none' is selected, include all patterns
        relevantPatterns.addAll(ProteinPreferences.allIngredientPatterns);
        break;
      } else if (proteinPreferenceToPatterns.containsKey(preference)) {
        relevantPatterns.addAll(proteinPreferenceToPatterns[preference]!);
      }
    }
    
    // Score recipes by protein preferences but don't exclude any
    final recipeScores = <Map<String, dynamic>, double>{};
    
    logDebug('🔍 Processing ${allRecipes.length} recipes for protein scoring...');
    for (final recipe in allRecipes) {
      logDebug('  - ${recipe['title']}');
    }
    
    for (final recipe in allRecipes) {
      final recipeId = recipe['id'] as String;
      final ingredientNames = recipeIngredientMap[recipeId] ?? [];
      
      double proteinScore = 0;
      
      // Check how many protein preferences this recipe matches
      int matchingProteins = 0;
      for (final preference in proteinPreferences) {
        if (preference == 'none') continue; // Skip 'none' preference
        
        final patterns = proteinPreferenceToPatterns[preference] ?? [];
        final hasThisProtein = ingredientNames.any((ingredientName) {
          return patterns.any((pattern) => 
            ingredientName.toLowerCase().contains(pattern.toLowerCase()));
        });
        
        if (hasThisProtein) {
          matchingProteins++;
        }
      }
      
      // Give higher score for matching more protein preferences
      if (matchingProteins > 0) {
        proteinScore = 10 + (matchingProteins - 1) * 5; // Base 10 + 5 bonus per additional protein
      } else {
        proteinScore = 1; // Low but non-zero score for non-matching recipes
      }
      
      recipeScores[recipe] = proteinScore;
      
      // Debug logging for Tomato Eggs and 牛肉炒饭 specifically
      if (recipe['title']?.toString().toLowerCase().contains('tomato eggs') == true || 
          recipe['title']?.toString().contains('牛肉炒饭') == true) {
        logDebug('🔍 DEBUG ${recipe['title']}:');
        logDebug('  - Ingredients: $ingredientNames');
        logDebug('  - Selected preferences: $proteinPreferences');
        logDebug('  - Matching proteins: $matchingProteins out of ${proteinPreferences.length}');
        logDebug('  - Protein score: $proteinScore');
        
        // Debug each ingredient
        for (final ingredient in ingredientNames) {
          for (final preference in proteinPreferences) {
            if (preference == 'none') continue;
            final patterns = proteinPreferenceToPatterns[preference] ?? [];
            final matches = patterns.any((pattern) => 
              ingredient.toLowerCase().contains(pattern.toLowerCase()));
            if (matches) {
              logDebug('    ✅ "$ingredient" matches "$preference" pattern');
            }
          }
        }
      }
      
      logDebug('Recipe: ${recipe['title']} - Protein score: $proteinScore');
    }

    // Sort recipes by protein score (highest first) but keep all recipes available
    final sortedByProtein = recipeScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final recipesToUse = sortedByProtein.map((entry) => entry.key).toList();
    
    logDebug('Total recipes available: ${allRecipes.length}');
    logDebug('Recipes sorted by protein preference: ${recipesToUse.map((r) => r['title']).toList()}');

    // Get the start of this week (Monday)
    final today = DateTime.now();
    final daysFromMonday = today.weekday - 1;
    final weekStart = today.subtract(Duration(days: daysFromMonday));
    
    // Select unique recipes based on configuration, protein preferences, and store optimization
    final selectedRecipes = await _selectOptimalRecipes(client, recipesToUse, uniqueRecipeTypes, recipeScores, user.id);
    final totalMeals = totalDays * mealsPerDay;
    
    logDebug('Configuration: $uniqueRecipeTypes unique types, $totalDays days, $mealsPerDay meals/day = $totalMeals total meals');
    logDebug('Selected recipes: ${selectedRecipes.map((r) => r['title']).toList()}');
    
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
    
    logDebug('Generated plan with ${planData.length} meal slots using ${selectedRecipes.length} unique recipes');
    logDebug('Plan data being saved: $planData');

    // Insert new weekly plan (always create new entry)
    logDebug('INSERTING NEW PLAN TO DATABASE...');
    
    // Filter out invalid enum values for protein_priority
    final validProteinPreferences = proteinPreferences.where((pref) => 
      ['chicken', 'beef', 'pork', 'fish', 'seafood', 'vegetarian', 'vegan'].contains(pref)
    ).toList();
    
    logDebug('Original protein preferences: $proteinPreferences');
    logDebug('Valid protein preferences: $validProteinPreferences');
    
    // Use upsert to update existing plan or create new one
    try {
      final weeklyPlanResponse = await client.from('meal_plans').upsert({
        'user_id': user.id,
        'week_start_date': weekStart.toIso8601String().split('T')[0],
        'plan': planData,
      }, onConflict: 'user_id,week_start_date').select('id').single();
      logDebug('DATABASE INSERT RESPONSE: $weeklyPlanResponse');
      
      final weeklyPlanId = weeklyPlanResponse['id'] as String;
      logDebug('Weekly plan created successfully with ID: $weeklyPlanId');
      logDebug('Plan saved with ${planData.length} meal slots');
      logDebug('RETURNING PLAN ID: $weeklyPlanId');
      
      // Auto-generate shopping list after creating weekly plan
      logDebug('🛒 Starting shopping list generation for plan: $weeklyPlanId');
      try {
        await _generateShoppingListFromPlan(client, user.id, weeklyPlanId, planData);
        logDebug('✅ Shopping list auto-generated successfully!');
        
        // Trigger shopping list refresh after generation
        ref.read(shoppingListRefreshProvider.notifier).state++;
        logDebug('🔄 Shopping list refresh triggered');
      } catch (e) {
        logDebug('❌ Failed to auto-generate shopping list: $e');
        logDebug('❌ Stack trace: ${StackTrace.current}');
        // Don't throw here - weekly plan was created successfully
      }
      
      // Return the plan ID so the UI can use it for targeted refresh
      return weeklyPlanId;
      
    } catch (e) {
      logDebug('DATABASE INSERT FAILED: $e');
      rethrow;
    }
});

final shoppingListProvider = StreamProvider<List<ShoppingListItem>>((ref) async* {
  // Watch the refresh trigger to force refresh when needed
  final refreshTrigger = ref.watch(shoppingListRefreshProvider);
  logDebug('Shopping list provider triggered with refresh: $refreshTrigger');
  
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    logDebug('No user found for shopping list');
    yield <ShoppingListItem>[];
    return;
  }

  logDebug('Setting up shopping list provider for user: ${user.id}');
  
  // Load shopping list items
  final items = await _loadShoppingListForUser(user.id);
  logDebug('Shopping list provider yielding ${items.length} items');
  yield items;
});

// Helper function to load shopping list for a user
Future<List<ShoppingListItem>> _loadShoppingListForUser(String userId) async {
  try {
    logDebug('Loading shopping list for user: $userId');
    
    // Get user's most recent weekly plan only
    final userWeeklyPlans = await SupabaseService.client
        .from('meal_plans')
        .select('id, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);
    
    logDebug('Found ${userWeeklyPlans.length} weekly plans for user');
    
    if (userWeeklyPlans.isEmpty) {
      logDebug('No weekly plans found - returning empty shopping list');
      return <ShoppingListItem>[];
    }
    
    // Only use the most recent weekly plan
    final latestPlan = userWeeklyPlans.first;
    final latestPlanId = latestPlan['id'] as String;
    logDebug('Using latest weekly plan ID: $latestPlanId');
    
    // Get shopping list items for the latest weekly plan only
    logDebug('🔍 Querying shopping_list_items for latest weekly plan ID: $latestPlanId');
    final shoppingItems = await SupabaseService.client
        .from('shopping_list_items')
        .select('*')
        .eq('meal_plan_id', latestPlanId)
        .order('id');
    
    logDebug('🔍 Found ${shoppingItems.length} shopping list items');
    if (shoppingItems.isNotEmpty) {
      logDebug('🔍 Shopping list items: ${shoppingItems.map((item) => '${item['ingredient_id']} (plan: ${item['meal_plan_id']})').toList()}');
    }
    
    if (shoppingItems.isEmpty) {
      logDebug('No shopping list items found - returning empty list');
      return <ShoppingListItem>[];
    }
    
    // Get store and ingredient names
    final storeIds = shoppingItems.map((r) => r['store_id'] as String?).whereType<String>().toSet().toList();
    final ingredientIds = shoppingItems.map((r) => r['ingredient_id'] as String).toSet().toList();
    
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
    for (final row in shoppingItems) {
      final storeId = row['store_id'] as String?;
      final ingredientId = row['ingredient_id'] as String;
      
      items.add(ShoppingListItem(
        id: row['id'] as String,
        ingredientName: ingredients[ingredientId] ?? 'Unknown Ingredient',
        storeId: storeId,
        storeName: storeId != null ? stores[storeId] : null,
        unit: row['unit'] as String?,
        qty: (row['quantity'] as num?)?.toDouble(),
        purchased: (row['is_checked'] as bool?) ?? false,
      ));
    }
    
    logDebug('Processed ${items.length} shopping list items');
    return items;
    
  } catch (e) {
    logDebug('Error loading shopping list for user $userId: $e');
    return <ShoppingListItem>[];
  }
}

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
      .from('meal_plans')
      .select('id, plan')
      .eq('user_id', user.id)
      .order('week_start_date', ascending: false)
      .limit(1);
  
  logDebug('Weekly plans found: ${weeklyPlans.length}');
  logDebug('Weekly plans data: $weeklyPlans');
  
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
  
  logDebug('Plan data: $planData');
  logDebug('Recipe counts: $recipeCounts');
  logDebug('Recipe IDs: $recipeIds');
  
  // Get all ingredients for these recipes
  final recipeIngredients = await client
      .from('recipe_ingredients')
      .select('recipe_id, ingredient_id, quantity, unit, ingredients!inner(name)')
      .inFilter('recipe_id', recipeIds);
  
  logDebug('Recipe IDs: $recipeIds');
  logDebug('Recipe ingredients count: ${recipeIngredients.length}');
  
  // Group ingredients by name and sum quantities (multiplied by meal count)
  final ingredientMap = <String, Map<String, dynamic>>{};
  for (final ri in recipeIngredients) {
    try {
      final recipeId = ri['recipe_id'] as String?;
      if (recipeId == null) {
        logDebug('Warning: recipe_id is null for ingredient: $ri');
        continue;
      }
      
      final mealCount = recipeCounts[recipeId] ?? 1;
      final ingredientName = ri['ingredients']?['name'] as String? ?? 'Unknown';
      final quantity = (ri['quantity'] as num? ?? 0) * mealCount; // Multiply by meal count
      final unit = ri['unit'] as String? ?? 'unit';
      
      logDebug('Processing ingredient: $ingredientName, qty: $quantity, unit: $unit (x$mealCount meals)');
      
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
      logDebug('Error processing ingredient: $e');
      logDebug('Raw ingredient data: $ri');
    }
  }
  
  // Clear existing shopping list items
  await client.from('shopping_list_items').delete().eq('meal_plan_id', weeklyPlanId);
  
  // Get stores and their items to categorize ingredients
  final stores = await client
      .from('stores')
      .select('id, name')
      .eq('user_id', user.id)
      .order('priority');
  
  final storeItems = await client
      .from('store_items')
      .select('store_id, ingredient_id, ingredients!inner(name)');
  
  logDebug('Store items found: ${storeItems.length}');
  logDebug('Store items data: $storeItems');
  
  // Debug: Check which stores have beef
  final beefStores = storeItems.where((item) => 
    (item['ingredients']?['name'] as String?)?.toLowerCase() == 'beef').toList();
  logDebug('Beef availability: ${beefStores.map((item) => {
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
      logDebug('Mapped ingredient: $ingredientName -> store: $storeId');
    }
  }
  
  logDebug('Total ingredient mappings: ${ingredientToStore.length}');
  logDebug('Ingredient mappings: $ingredientToStore');
  
  // Group ingredients by store
  final storeIngredientMap = <String, List<Map<String, dynamic>>>{};
  for (final ingredient in ingredientMap.values) {
    final ingredientName = ingredient['name'] as String;
    final storeId = ingredientToStore[ingredientName];
    
    logDebug('Ingredient: $ingredientName -> Store ID: $storeId');
    
    if (storeId != null) {
      storeIngredientMap.putIfAbsent(storeId, () => []).add(ingredient);
    } else {
      // If no store found, put in "No Store"
      storeIngredientMap.putIfAbsent('no_store', () => []).add(ingredient);
    }
  }
  
  logDebug('Store ingredient mapping: ${storeIngredientMap.keys.toList()}');
  logDebug('Total ingredients to process: ${ingredientMap.length}');
  
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
    
    logDebug('Processing store: ${storeEntry.key} -> $storeName (${ingredients.length} ingredients)');
    
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
      logDebug('💾 Inserting shopping list item: ingredient=$ingredientId, store=$storeId, plan=$weeklyPlanId');
      await client.from('shopping_list_items').insert({
        'meal_plan_id': weeklyPlanId,
        'ingredient_id': ingredientId,
        'store_id': storeId,
        'quantity': ingredient['quantity'],
        'unit': ingredient['unit'],
        'is_checked': false,
      });
    }
  }
  
  logDebug('Shopping list generation completed successfully!');
  logDebug('Total ingredients processed: ${ingredientMap.length}');
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
  
  logDebug('🛒 Auto-generating shopping list for ${recipeIds.length} recipes');
  logDebug('🛒 Recipe IDs: $recipeIds');
  
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
        logDebug('Warning: recipe_id is null for ingredient: $ri');
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
      logDebug('Error processing ingredient: $e');
    }
  }
  
  // Get home inventory to exclude from shopping list
  final homeInventory = await client
      .from('home_inventory')
      .select('ingredient_name')
      .eq('user_id', userId);
  
  final homeIngredientNames = homeInventory
      .map((item) => (item['ingredient_name'] as String).toLowerCase())
      .toSet();
  
  logDebug('🏠 Found ${homeIngredientNames.length} home inventory items: $homeIngredientNames');
  
  // Filter out ingredients that are at home
  final shoppingIngredients = <String, Map<String, dynamic>>{};
  for (final entry in ingredientMap.entries) {
    final ingredientName = entry.key;
    final ingredientData = entry.value;
    
    if (!homeIngredientNames.contains(ingredientName.toLowerCase())) {
      shoppingIngredients[ingredientName] = ingredientData;
    } else {
      logDebug('🏠 Excluding "$ingredientName" from shopping list (available at home)');
    }
  }
  
  logDebug('🛒 After filtering home inventory: ${shoppingIngredients.length} ingredients need shopping');
  
  // Clear existing shopping list items
  await client.from('shopping_list_items').delete().eq('meal_plan_id', weeklyPlanId);
  
  // Get stores and their items to categorize ingredients
  final storeItems = await client
      .from('store_items')
      .select('store_id, ingredient_id, ingredients!inner(name)');
  
  // Get store priorities for ingredient assignment
  final stores = await client
      .from('stores')
      .select('id, name, priority')
      .order('priority', ascending: true);
  
  final storePriorities = <String, int>{};
  for (final store in stores) {
    final storeId = store['id'] as String;
    final priority = store['priority'] as int? ?? 10;
    final name = store['name'] as String;
    storePriorities[storeId] = priority;
    logDebug('🏪 Store: $name (ID: $storeId, Priority: $priority)');
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
    
    // Skip if no stores are available for this ingredient
    if (availableStores.isEmpty) {
      logDebug('⚠️ No stores available for ingredient: $ingredientName - assigning to no_store');
      ingredientToStore[ingredientName] = 'no_store';
      continue;
    }
    
    // Sort stores by priority (lower number = higher priority)
    availableStores.sort((a, b) {
      final priorityA = storePriorities[a] ?? 10;
      final priorityB = storePriorities[b] ?? 10;
      
      // Sort by priority (lower number = higher priority)
      return priorityA.compareTo(priorityB);
    });
    
    // Assign to the highest priority store
    final selectedStoreId = availableStores.first;
    ingredientToStore[ingredientName] = selectedStoreId;
    
    if (ingredientName.toLowerCase() == 'beef') {
      final selectedStoreName = stores.firstWhere((s) => s['id'] == selectedStoreId, orElse: () => {'name': 'Unknown'})['name'];
      final selectedStorePriority = storePriorities[selectedStoreId] ?? 10;
      logDebug('🐄 Beef assigned to: $selectedStoreName (Priority: $selectedStorePriority)');
      logDebug('🐄 Available stores for beef: ${availableStores.map((id) => {
        'name': stores.firstWhere((s) => s['id'] == id, orElse: () => {'name': 'Unknown'})['name'],
        'priority': storePriorities[id] ?? 10,
      }).toList()}');
      logDebug('🐄 Ingredient name: "$ingredientName" (exact match: ${ingredientName.toLowerCase() == 'beef'})');
    }
  }
  
  logDebug('Ingredient-to-store assignment (priority-based):');
  for (final entry in ingredientToStore.entries) {
    final storeName = stores.firstWhere((s) => s['id'] == entry.value, orElse: () => {'name': 'Unknown'})['name'];
    final priority = storePriorities[entry.value] ?? 10;
    logDebug('  ${entry.key} → $storeName (Priority: $priority)');
  }
  
  // Optimize store visits by consolidating ingredients
  final storeIngredientMap = <String, List<Map<String, dynamic>>>{};
  final unassignedIngredients = <Map<String, dynamic>>[];
  
  // First pass: assign ingredients to stores where they're available
  for (final ingredient in shoppingIngredients.values) {
    final ingredientName = ingredient['name'] as String;
    final storeId = ingredientToStore[ingredientName];
    
    if (storeId != null) {
      storeIngredientMap.putIfAbsent(storeId, () => []).add(ingredient);
      logDebug('Initial assignment: $ingredientName → ${stores.firstWhere((s) => s['id'] == storeId, orElse: () => {'name': 'Unknown'})['name']}');
    } else {
      unassignedIngredients.add(ingredient);
    }
  }
  
  logDebug('Before optimization: ${storeIngredientMap.map((k, v) => MapEntry(stores.firstWhere((s) => s['id'] == k, orElse: () => {'name': 'Unknown'})['name'], v.length))}');
  
  // Second pass: optimize by consolidating ingredients to minimize store visits
  await _optimizeStoreVisits(client, storeIngredientMap, unassignedIngredients);
  
  logDebug('After optimization: ${storeIngredientMap.map((k, v) => MapEntry(stores.firstWhere((s) => s['id'] == k, orElse: () => {'name': 'Unknown'})['name'], v.length))}');
  
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
      logDebug('💾 Inserting shopping list item: ingredient=$ingredientId, store=$storeId, plan=$weeklyPlanId');
      await client.from('shopping_list_items').insert({
        'meal_plan_id': weeklyPlanId,
        'ingredient_id': ingredientId,
        'store_id': storeId,
        'quantity': ingredient['quantity'],
        'unit': ingredient['unit'],
        'is_checked': false,
      });
    }
  }
  
  logDebug('Auto-generated shopping list with ${shoppingIngredients.length} ingredients');
}

// Helper function to select optimal recipes that minimize store visits
Future<List<Map<String, dynamic>>> _selectOptimalRecipes(
  dynamic client,
  List<Map<String, dynamic>> availableRecipes,
  int uniqueRecipeTypes,
  Map<Map<String, dynamic>, double> proteinScores,
  String userId,
) async {
  if (availableRecipes.isEmpty) return [];
  
  logDebug('Selecting optimal recipes to minimize store visits while considering protein preferences and home inventory...');
  
  // Get home inventory to prioritize recipes with home ingredients
  final homeInventory = await client
      .from('home_inventory')
      .select('ingredient_name')
      .eq('user_id', userId);
  
  final homeIngredientNames = homeInventory
      .map((item) => (item['ingredient_name'] as String).toLowerCase())
      .toSet();
  
  logDebug('🏠 Home inventory ingredients: $homeIngredientNames');
  
  // Get store priorities
  final stores = await client
      .from('stores')
      .select('id, name, priority')
      .order('priority', ascending: true);
  
  final storePriorities = <String, int>{};
  for (final store in stores) {
    storePriorities[store['id'] as String] = store['priority'] as int? ?? 10;
  }
  
  logDebug('🏪 Store priorities: $storePriorities');
  
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
  
  // Get ingredients for each recipe and combine protein + store + home inventory scores
  final combinedScores = <Map<String, dynamic>, double>{};
  
  for (final recipe in availableRecipes) {
    final recipeId = recipe['id'] as String;
    
    // Get ingredients for this recipe
    final recipeIngredients = await client
        .from('recipe_ingredients')
        .select('ingredients!inner(name)')
        .eq('recipe_id', recipeId);
    
    double storeScore = 0;
    int totalIngredients = 0;
    int homeIngredients = 0;
    int noStoreIngredients = 0;
    final storeUsage = <String, int>{};
    int actualStores = 0;
    
    for (final ri in recipeIngredients) {
      final ingredientName = ri['ingredients']?['name'] as String?;
      if (ingredientName != null) {
        totalIngredients++;
        
        // Check if ingredient is available at home first
        if (homeIngredientNames.contains(ingredientName.toLowerCase())) {
          homeIngredients++;
          logDebug('🏠 Recipe ${recipe['name']} uses home ingredient: $ingredientName');
        } else {
          // Check if this ingredient is available in stores
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
            final ingredientScore = (11 - priority); // Invert priority so higher priority = higher score
            storeScore += ingredientScore;
            
            // Debug logging for store scoring
            if (recipe['title']?.toString().toLowerCase().contains('tomato eggs') == true) {
              logDebug('    🛒 Ingredient "$ingredientName" -> Store priority $priority -> Score +$ingredientScore');
            }
          } else {
            // Track ingredients not available at any store
            noStoreIngredients++;
            storeScore -= 5;
          }
        }
      }
    }
    
    if (totalIngredients > 0) {
      // Count actual stores needed (including "No Store" as a store)
      actualStores = storeUsage.keys.length + (noStoreIngredients > 0 ? 1 : 0);
      final consolidationBonus = totalIngredients / actualStores; // Higher is better
      storeScore += consolidationBonus * 2;
      
      // Penalty for recipes that require many stores
      if (actualStores > 2) {
        storeScore -= (actualStores - 2) * 3;
      }
      
      // Don't add home inventory bonus - home ingredients already reduce store visits
      // which is the real benefit. Scoring them separately creates double-counting.
    }
    
    // Combine protein preference score with store optimization and home inventory scores
    final proteinScore = proteinScores[recipe] ?? 1;
    final combinedScore = proteinScore * 5 + storeScore; // Weight protein preferences more heavily
    
    combinedScores[recipe] = combinedScore;
    
    // Debug logging for Tomato Eggs specifically
    if (recipe['title']?.toString().toLowerCase().contains('tomato eggs') == true) {
      logDebug('🍅 FINAL DEBUG Tomato Eggs:');
      logDebug('  - Protein score: ${proteinScore.toStringAsFixed(1)}');
      logDebug('  - Store score: ${storeScore.toStringAsFixed(1)}');
      logDebug('  - Combined score: ${combinedScore.toStringAsFixed(1)}');
      logDebug('  - Actual stores needed: $actualStores (${storeUsage.keys.length} real stores + ${noStoreIngredients > 0 ? 1 : 0} no-store)');
      logDebug('  - Total ingredients: $totalIngredients');
      logDebug('  - Home ingredients: $homeIngredients/$totalIngredients');
      logDebug('  - No-store ingredients: $noStoreIngredients');
      logDebug('  - Store usage: $storeUsage');
    }
    
    final recipeTitle = recipe['title'];
    logDebug('Recipe "$recipeTitle": protein=${proteinScore.toStringAsFixed(1)}, store=${storeScore.toStringAsFixed(1)}, combined=${combinedScore.toStringAsFixed(1)}, stores=$actualStores, ingredients=$totalIngredients, home=$homeIngredients/$totalIngredients, no-store=$noStoreIngredients');
  }
  
  // Sort recipes by combined score (highest first) and take the top ones
  final sortedRecipes = combinedScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  // Ensure we always return the requested number of recipes, even if we need to include lower-scoring ones
  final selectedRecipes = <Map<String, dynamic>>[];
  
  // Take up to the requested number, but ensure we get exactly that many if possible
  for (int i = 0; i < uniqueRecipeTypes && i < sortedRecipes.length; i++) {
    selectedRecipes.add(sortedRecipes[i].key);
  }
  
  logDebug('Requested $uniqueRecipeTypes unique recipes');
  logDebug('Available recipes: ${sortedRecipes.length}');
  final formattedSelectedRecipes = selectedRecipes
      .map((recipe) {
        final title = recipe['title'];
        final score = combinedScores[recipe]?.toStringAsFixed(1);
        return '$title (score: $score)';
      })
      .join(', ');
  logDebug('Selected ${selectedRecipes.length} recipes: $formattedSelectedRecipes');
  
  if (selectedRecipes.length < uniqueRecipeTypes) {
    logDebug('WARNING: Only found ${selectedRecipes.length} recipes, requested $uniqueRecipeTypes');
  }
  
  return selectedRecipes;
}

// Helper function to optimize store visits by consolidating ingredients
Future<void> _optimizeStoreVisits(
  dynamic client,
  Map<String, List<Map<String, dynamic>>> storeIngredientMap,
  List<Map<String, dynamic>> unassignedIngredients,
) async {
  logDebug('Optimizing store visits...');
  
  // Get all stores with their priority
  final stores = await client
      .from('stores')
      .select('id, name, priority')
      .order('priority', ascending: true);
  
  // Create store priority map (lower number = higher priority)
  final storePriorities = <String, int>{};
  
  for (final store in stores) {
    final storeId = store['id'] as String;
    final priority = store['priority'] as int? ?? 10;
    
    storePriorities[storeId] = priority;
  }
  
  // Strategy 1: Prioritize minimizing store visits, then use store priority as tiebreaker
  final storeSizes = <String, int>{};
  for (final entry in storeIngredientMap.entries) {
    storeSizes[entry.key] = entry.value.length;
  }
  
  // Sort stores by priority first (lower number = higher priority), then by size
  final sortedStores = storeIngredientMap.keys.toList()
    ..sort((a, b) {
      final priorityA = storePriorities[a] ?? 10;
      final priorityB = storePriorities[b] ?? 10;
      final sizeA = storeSizes[a] ?? 0;
      final sizeB = storeSizes[b] ?? 0;
      
      // First priority: higher priority stores (lower number)
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      // Second priority: larger stores (for better consolidation)
      return sizeB.compareTo(sizeA);
    });
  
  logDebug('Store optimization order (by priority): ${sortedStores.map((id) => '${stores.firstWhere((s) => s['id'] == id, orElse: () => {'name': 'Unknown'})['name']} (Priority: ${storePriorities[id]}, ${storeSizes[id]} items)').join(', ')}');
  
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
    logDebug('Primary consolidation target: ${stores.firstWhere((s) => s['id'] == primaryStore, orElse: () => {'name': 'Unknown'})['name']} (Priority: ${storePriorities[primaryStore]})');
    
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
        logDebug('🔍 Checking ingredient $ingredientName: available at stores $availableStores, primary store $primaryStore');
        if (availableStores.contains(primaryStore)) {
          // This ingredient is available at the primary store, move it
          logDebug('✅ Moving $ingredientName to primary store $primaryStore');
          ingredientsToMove.add(ingredient);
          processedIngredients.add(ingredientName);
        } else {
          logDebug('❌ $ingredientName NOT available at primary store $primaryStore, keeping at source store');
          remainingIngredients.add(ingredient);
        }
      }
      
      if (ingredientsToMove.isNotEmpty) {
        logDebug('Moving ${ingredientsToMove.length} ingredients from ${stores.firstWhere((s) => s['id'] == sourceStoreId, orElse: () => {'name': 'Unknown'})['name']} to ${stores.firstWhere((s) => s['id'] == primaryStore, orElse: () => {'name': 'Unknown'})['name']}');
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
        logDebug('Moving ${ingredientsToMove.length} ingredients from ${stores.firstWhere((s) => s['id'] == sourceStoreId, orElse: () => {'name': 'Unknown'})['name']} to ${stores.firstWhere((s) => s['id'] == targetStoreId, orElse: () => {'name': 'Unknown'})['name']}');
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
  
  // Assign unassigned ingredients to "no_store" (don't assume any store carries them)
  if (unassignedIngredients.isNotEmpty) {
    optimizedStoreMap.putIfAbsent('no_store', () => []).addAll(unassignedIngredients);
    logDebug('Assigned ${unassignedIngredients.length} unassigned ingredients to no specific store (no_store)');
  }
  
  // Update the store ingredient map
  storeIngredientMap.clear();
  storeIngredientMap.addAll(optimizedStoreMap);
  
  logDebug('Final store consolidation:');
  for (final entry in storeIngredientMap.entries) {
    final storeName = entry.key == 'no_store' ? 'No specific store' : 
        stores.firstWhere((s) => s['id'] == entry.key, orElse: () => {'name': 'Unknown'})['name'];
    logDebug('  $storeName: ${entry.value.map((i) => i['name']).join(', ')}');
  }
  
  // Print optimization results
  final totalStores = storeIngredientMap.keys.where((id) => id != 'no_store').length;
  logDebug('Store optimization complete!');
  logDebug('Total stores to visit: $totalStores');
  
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
    logDebug('  - $storeName (Priority: $priority): ${entry.value.length} items');
  }
}
