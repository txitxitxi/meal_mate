import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moduels.dart';
import '../services/supabase_service.dart';
import 'auth_providers.dart';

// Add a refresh trigger for meal plans
final mealPlanRefreshProvider = StateProvider<int>((ref) => 0);

// Add a refresh trigger for shopping lists
final shoppingListRefreshProvider = StateProvider<int>((ref) => 0);

final mealPlanProvider = StreamProvider<List<MealPlanEntry>>((ref) async* {
  // Watch the refresh trigger to force refresh when needed
  final refreshTrigger = ref.watch(mealPlanRefreshProvider);
  print('Meal plan provider triggered with refresh: $refreshTrigger');
  
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    print('No user found, returning empty meal plan');
    yield <MealPlanEntry>[];
    return;
  }

  print('Loading meal plan for user: ${user.id}');
  
  // Force a fresh query every time by adding the refresh trigger to the query
  final rows = await SupabaseService.client
      .from('weekly_plans')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(1);
  
  print('Found ${rows.length} weekly plans');
  if (rows.isNotEmpty) {
    final plan = rows.first;
    print('Latest plan ID: ${plan['id']}');
    print('Latest plan created_at: ${plan['created_at']}');
    print('Latest plan week_start_date: ${plan['week_start_date']}');
    print('LOADING PLAN WITH ID: ${plan['id']}');
  }
  
  final entries = <MealPlanEntry>[];
  
  if (rows.isNotEmpty) {
    final plan = rows.first;
    final planData = plan['plan'] as Map<String, dynamic>?;
    
    if (planData != null) {
      print('Processing plan data: $planData');
      
      // Get all unique recipe IDs from the plan
      final recipeIds = planData.values.whereType<String>().toList();
      print('Recipe IDs from plan: $recipeIds');
      
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
        print('Fetched ${recipes.length} recipes');
      }
      
      // Count occurrences of each recipe
      final recipeCounts = <String, int>{};
      for (final recipeId in recipeIds) {
        recipeCounts[recipeId] = (recipeCounts[recipeId] ?? 0) + 1;
      }
      print('Recipe counts: $recipeCounts');
      
      // Create entries for unique recipes with their counts
      for (final entry in recipeCounts.entries) {
        final recipeId = entry.key;
        final count = entry.value;
        final recipeData = recipes[recipeId];
        
        entries.add(MealPlanEntry(
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
  
  print('Meal plan entries created: ${entries.length}');
  print('Entries: ${entries.map((e) => '${e.recipe.title} (${e.count}x)').toList()}');
  
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
        .inFilter('id', savedRecipeIds.map((s) => s['recipe_id'] as String).toList());
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
  
  print('User own recipes: ${userOwnRecipes.length}');
  print('Saved recipes: ${savedRecipes.length}');
  print('Total unique recipes for meal planning: ${allRecipes.length}');
  print('Recipe titles: ${allRecipes.map((r) => r['title']).toList()}');

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
    
    // Score recipes by protein preferences but don't exclude any
    final recipeScores = <Map<String, dynamic>, double>{};
    
    for (final recipe in allRecipes) {
      final recipeId = recipe['id'] as String;
      final ingredientNames = recipeIngredientMap[recipeId] ?? [];
      
      double proteinScore = 0;
      
      // Check if recipe has any ingredient names that match preferences
      final hasMatchingProtein = ingredientNames.any((ingredientName) {
        return relevantPatterns.any((pattern) => ingredientName.contains(pattern));
      });
      
      // Give higher score to recipes that match protein preferences
      if (hasMatchingProtein) {
        proteinScore = 10; // High score for matching recipes
      } else {
        proteinScore = 1; // Low but non-zero score for non-matching recipes
      }
      
      recipeScores[recipe] = proteinScore;
      
      print('Recipe: ${recipe['title']} - Protein score: $proteinScore');
    }

    // Sort recipes by protein score (highest first) but keep all recipes available
    final sortedByProtein = recipeScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final recipesToUse = sortedByProtein.map((entry) => entry.key).toList();
    
    print('Total recipes available: ${allRecipes.length}');
    print('Recipes sorted by protein preference: ${recipesToUse.map((r) => r['title']).toList()}');

    // Get the start of this week (Monday)
    final today = DateTime.now();
    final daysFromMonday = today.weekday - 1;
    final weekStart = today.subtract(Duration(days: daysFromMonday));
    
    // Select unique recipes based on configuration, protein preferences, and store optimization
    final selectedRecipes = await _selectOptimalRecipes(client, recipesToUse, uniqueRecipeTypes, recipeScores);
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
    print('Plan data being saved: $planData');

    // Insert new weekly plan (always create new entry)
    print('INSERTING NEW PLAN TO DATABASE...');
    
    // Filter out invalid enum values for protein_priority
    final validProteinPreferences = proteinPreferences.where((pref) => 
      ['chicken', 'beef', 'pork', 'fish', 'seafood', 'vegetarian', 'vegan'].contains(pref)
    ).toList();
    
    print('Original protein preferences: $proteinPreferences');
    print('Valid protein preferences: $validProteinPreferences');
    
    // Use upsert to update existing plan or create new one
    try {
      final weeklyPlanResponse = await client.from('weekly_plans').upsert({
        'user_id': user.id,
        'week_start_date': weekStart.toIso8601String().split('T')[0],
        'plan': planData,
      }, onConflict: 'user_id,week_start_date').select('id').single();
      print('DATABASE INSERT RESPONSE: $weeklyPlanResponse');
      
      final weeklyPlanId = weeklyPlanResponse['id'] as String;
      print('Weekly plan created successfully with ID: $weeklyPlanId');
      print('Plan saved with ${planData.length} meal slots');
      print('RETURNING PLAN ID: $weeklyPlanId');
      
      // Auto-generate shopping list after creating weekly plan
      print('🛒 Starting shopping list generation for plan: $weeklyPlanId');
      try {
        await _generateShoppingListFromPlan(client, user.id, weeklyPlanId, planData);
        print('✅ Shopping list auto-generated successfully!');
        
        // Trigger shopping list refresh after generation
        ref.read(shoppingListRefreshProvider.notifier).state++;
        print('🔄 Shopping list refresh triggered');
      } catch (e) {
        print('❌ Failed to auto-generate shopping list: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        // Don't throw here - weekly plan was created successfully
      }
      
      // Return the plan ID so the UI can use it for targeted refresh
      return weeklyPlanId;
      
    } catch (e) {
      print('DATABASE INSERT FAILED: $e');
      rethrow;
    }
});

final shoppingListProvider = StreamProvider<List<ShoppingListItem>>((ref) async* {
  // Watch the refresh trigger to force refresh when needed
  final refreshTrigger = ref.watch(shoppingListRefreshProvider);
  print('Shopping list provider triggered with refresh: $refreshTrigger');
  
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    print('No user found for shopping list');
    yield <ShoppingListItem>[];
    return;
  }

  print('Setting up shopping list provider for user: ${user.id}');
  
  // Load shopping list items
  final items = await _loadShoppingListForUser(user.id);
  print('Shopping list provider yielding ${items.length} items');
  yield items;
});

// Helper function to load shopping list for a user
Future<List<ShoppingListItem>> _loadShoppingListForUser(String userId) async {
  try {
    print('Loading shopping list for user: $userId');
    
    // Get user's weekly plans
    final userWeeklyPlans = await SupabaseService.client
        .from('weekly_plans')
        .select('id')
        .eq('user_id', userId);
    
    print('Found ${userWeeklyPlans.length} weekly plans for user');
    
    if (userWeeklyPlans.isEmpty) {
      print('No weekly plans found - returning empty shopping list');
      return <ShoppingListItem>[];
    }
    
    final userWeeklyPlanIds = userWeeklyPlans.map((p) => p['id'] as String).toList();
    print('Weekly plan IDs: $userWeeklyPlanIds');
    
    // Get shopping list items for these weekly plans
    print('🔍 Querying shopping_list_items for weekly plan IDs: $userWeeklyPlanIds');
    final shoppingItems = await SupabaseService.client
        .from('shopping_list_items')
        .select('*')
        .inFilter('weekly_plan_id', userWeeklyPlanIds)
        .order('id');
    
    print('🔍 Found ${shoppingItems.length} shopping list items');
    if (shoppingItems.isNotEmpty) {
      print('🔍 Shopping list items: ${shoppingItems.map((item) => '${item['ingredient_id']} (plan: ${item['weekly_plan_id']})').toList()}');
    }
    
    if (shoppingItems.isEmpty) {
      print('No shopping list items found - returning empty list');
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
    
    print('Processed ${items.length} shopping list items');
    return items;
    
  } catch (e) {
    print('Error loading shopping list for user $userId: $e');
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
      .select('id, name')
      .eq('user_id', user.id)
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
      print('💾 Inserting shopping list item: ingredient=$ingredientId, store=$storeId, plan=$weeklyPlanId');
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
  
  print('🛒 Auto-generating shopping list for ${recipeIds.length} recipes');
  print('🛒 Recipe IDs: $recipeIds');
  
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
      .select('id, name, priority')
      .order('priority', ascending: true);
  
  final storePriorities = <String, int>{};
  for (final store in stores) {
    final storeId = store['id'] as String;
    final priority = store['priority'] as int? ?? 10;
    final name = store['name'] as String;
    storePriorities[storeId] = priority;
    print('🏪 Store: $name (ID: $storeId, Priority: $priority)');
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
      print('⚠️ No stores available for ingredient: $ingredientName - assigning to no_store');
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
      print('🐄 Beef assigned to: $selectedStoreName (Priority: $selectedStorePriority)');
      print('🐄 Available stores for beef: ${availableStores.map((id) => {
        'name': stores.firstWhere((s) => s['id'] == id, orElse: () => {'name': 'Unknown'})['name'],
        'priority': storePriorities[id] ?? 10,
      }).toList()}');
      print('🐄 Ingredient name: "$ingredientName" (exact match: ${ingredientName.toLowerCase() == 'beef'})');
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
      print('Initial assignment: $ingredientName → ${stores.firstWhere((s) => s['id'] == storeId, orElse: () => {'name': 'Unknown'})['name']}');
    } else {
      unassignedIngredients.add(ingredient);
    }
  }
  
  print('Before optimization: ${storeIngredientMap.map((k, v) => MapEntry(stores.firstWhere((s) => s['id'] == k, orElse: () => {'name': 'Unknown'})['name'], v.length))}');
  
  // Second pass: optimize by consolidating ingredients to minimize store visits
  await _optimizeStoreVisits(client, storeIngredientMap, unassignedIngredients);
  
  print('After optimization: ${storeIngredientMap.map((k, v) => MapEntry(stores.firstWhere((s) => s['id'] == k, orElse: () => {'name': 'Unknown'})['name'], v.length))}');
  
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
      print('💾 Inserting shopping list item: ingredient=$ingredientId, store=$storeId, plan=$weeklyPlanId');
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
  Map<Map<String, dynamic>, double> proteinScores,
) async {
  if (availableRecipes.isEmpty) return [];
  
  print('Selecting optimal recipes to minimize store visits while considering protein preferences...');
  
  // Get store priorities
  final stores = await client
      .from('stores')
      .select('id, name, priority')
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
  
  // Get ingredients for each recipe and combine protein + store optimization scores
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
          storeScore += (11 - priority); // Invert priority so higher priority = higher score
        } else {
          // Penalty for ingredients not available at any store
          storeScore -= 5;
        }
      }
    }
    
    if (totalIngredients > 0) {
      // Bonus for recipes that use fewer unique stores
      final uniqueStores = storeUsage.keys.length;
      final consolidationBonus = totalIngredients / uniqueStores; // Higher is better
      storeScore += consolidationBonus * 2;
      
      // Penalty for recipes that require many stores
      if (uniqueStores > 2) {
        storeScore -= (uniqueStores - 2) * 3;
      }
    }
    
    // Combine protein preference score with store optimization score
    final proteinScore = proteinScores[recipe] ?? 1;
    final combinedScore = proteinScore * 5 + storeScore; // Weight protein preferences more heavily
    
    combinedScores[recipe] = combinedScore;
    print('Recipe "${recipe['title']}": protein=${proteinScore.toStringAsFixed(1)}, store=${storeScore.toStringAsFixed(1)}, combined=${combinedScore.toStringAsFixed(1)}, stores=${storeUsage.keys.length}, ingredients=$totalIngredients');
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
  
  print('Requested $uniqueRecipeTypes unique recipes');
  print('Available recipes: ${sortedRecipes.length}');
  print('Selected ${selectedRecipes.length} recipes: ${selectedRecipes.map((r) => '${r['title']} (score: ${combinedScores[r]?.toStringAsFixed(1)})').join(', ')}');
  
  if (selectedRecipes.length < uniqueRecipeTypes) {
    print('WARNING: Only found ${selectedRecipes.length} recipes, requested $uniqueRecipeTypes');
  }
  
  return selectedRecipes;
}

// Helper function to optimize store visits by consolidating ingredients
Future<void> _optimizeStoreVisits(
  dynamic client,
  Map<String, List<Map<String, dynamic>>> storeIngredientMap,
  List<Map<String, dynamic>> unassignedIngredients,
) async {
  print('Optimizing store visits...');
  
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
  
  print('Store optimization order (by priority): ${sortedStores.map((id) => '${stores.firstWhere((s) => s['id'] == id, orElse: () => {'name': 'Unknown'})['name']} (Priority: ${storePriorities[id]}, ${storeSizes[id]} items)').join(', ')}');
  
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
    print('Primary consolidation target: ${stores.firstWhere((s) => s['id'] == primaryStore, orElse: () => {'name': 'Unknown'})['name']} (Priority: ${storePriorities[primaryStore]})');
    
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
        print('🔍 Checking ingredient $ingredientName: available at stores $availableStores, primary store $primaryStore');
        if (availableStores.contains(primaryStore)) {
          // This ingredient is available at the primary store, move it
          print('✅ Moving $ingredientName to primary store $primaryStore');
          ingredientsToMove.add(ingredient);
          processedIngredients.add(ingredientName);
        } else {
          print('❌ $ingredientName NOT available at primary store $primaryStore, keeping at source store');
          remainingIngredients.add(ingredient);
        }
      }
      
      if (ingredientsToMove.isNotEmpty) {
        print('Moving ${ingredientsToMove.length} ingredients from ${stores.firstWhere((s) => s['id'] == sourceStoreId, orElse: () => {'name': 'Unknown'})['name']} to ${stores.firstWhere((s) => s['id'] == primaryStore, orElse: () => {'name': 'Unknown'})['name']}');
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
        print('Moving ${ingredientsToMove.length} ingredients from ${stores.firstWhere((s) => s['id'] == sourceStoreId, orElse: () => {'name': 'Unknown'})['name']} to ${stores.firstWhere((s) => s['id'] == targetStoreId, orElse: () => {'name': 'Unknown'})['name']}');
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
    print('Assigned ${unassignedIngredients.length} unassigned ingredients to no specific store (no_store)');
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
