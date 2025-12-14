import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moduels.dart' hide Recipe; // Hide Recipe from moduels.dart to avoid conflict
import '../models/recipe.dart';
import '../services/supabase_service.dart';
import '../services/translation_service.dart';
import 'auth_providers.dart';
import '../utils/logger.dart';

// Provider to fetch supported protein enum values from the database
// This queries the database enum type dynamically to get all valid values
final supportedProteinValuesProvider = FutureProvider<Set<String>>((ref) async {
  try {
    final client = SupabaseService.client;
    
    // Query the database function to get all enum values for protein_pref
    final response = await client.rpc('get_protein_enum_values');
    
    // The RPC function returns a list of objects with 'enum_value' field
    final enumValues = <String>{};
    if (response is List) {
      for (final row in response) {
        if (row is Map && row['enum_value'] != null) {
          enumValues.add(row['enum_value'] as String);
        } else if (row is String) {
          enumValues.add(row);
        }
      }
    }
    
    logDebug('Found ${enumValues.length} protein enum values from database: $enumValues');
    
    // If we got values, return them; otherwise fall back to expected values
    if (enumValues.isNotEmpty) {
      return enumValues;
    } else {
      logDebug('No enum values returned, using fallback list.');
      // Fallback to all expected values after enum update
      return {
        'none',
        'chicken',
        'beef',
        'egg',
        'fish',
        'pork',
        'seafood',
        'tofu',
        'vegetarian',
        'vegan',
      };
    }
  } catch (e) {
    logDebug('Error querying protein enum values: $e. Using fallback list.');
    // Fallback to all expected values after enum update
    return {
      'none',
      'chicken',
      'beef',
      'egg',
      'fish',
      'pork',
      'seafood',
      'tofu',
      'vegetarian',
      'vegan',
    };
  }
});

// Helper function to map protein preference to database-compatible values
// Now uses the dynamically queried enum values from the database
String? _mapProteinForDatabase(ProteinPreference protein, Set<String>? supportedValues) {
  final proteinName = protein.name;
  
  // If we have the supported values list, use it
  // Otherwise, assume all values are supported (after enum update)
  final isSupported = supportedValues?.contains(proteinName) ?? true;
  
  if (isSupported) {
    return proteinName;
  } else {
    // Unsupported values are stored as null
    logDebug('Protein value "$proteinName" is not supported by database enum, storing as null');
    return null;
  }
}

// Helper function to categorize ingredients based on name
String _categorizeIngredient(String name) {
  final lowerName = name.toLowerCase();
  
  // Protein categories
  if (lowerName.contains('chicken') || lowerName.contains('turkey') || lowerName.contains('duck')) {
    return 'poultry';
  }
  if (lowerName.contains('beef') || lowerName.contains('pork') || lowerName.contains('lamb') || lowerName.contains('steak')) {
    return 'meat';
  }
  if (lowerName.contains('salmon') || lowerName.contains('tuna') || lowerName.contains('cod') || lowerName.contains('fish')) {
    return 'fish';
  }
  if (lowerName.contains('shrimp') || lowerName.contains('crab') || lowerName.contains('lobster') || lowerName.contains('scallop')) {
    return 'seafood';
  }
  if (lowerName.contains('milk') || lowerName.contains('cheese') || lowerName.contains('yogurt') || lowerName.contains('butter')) {
    return 'dairy';
  }
  if (lowerName.contains('bean') || lowerName.contains('lentil') || lowerName.contains('chickpea') || lowerName.contains('tofu')) {
    return 'legumes';
  }
  if (lowerName.contains('almond') || lowerName.contains('walnut') || lowerName.contains('peanut') || lowerName.contains('nut')) {
    return 'nuts';
  }
  
  // Non-protein categories
  if (lowerName.contains('broccoli') || lowerName.contains('carrot') || lowerName.contains('spinach') || 
      lowerName.contains('onion') || lowerName.contains('garlic') || lowerName.contains('tomato') ||
      lowerName.contains('pepper') || lowerName.contains('cucumber') || lowerName.contains('lettuce')) {
    return 'vegetable';
  }
  if (lowerName.contains('apple') || lowerName.contains('banana') || lowerName.contains('berry') || 
      lowerName.contains('orange') || lowerName.contains('lemon') || lowerName.contains('grape')) {
    return 'fruit';
  }
  if (lowerName.contains('rice') || lowerName.contains('pasta') || lowerName.contains('bread') || 
      lowerName.contains('flour') || lowerName.contains('oats') || lowerName.contains('quinoa')) {
    return 'grain';
  }
  if (lowerName.contains('salt') || lowerName.contains('pepper') || lowerName.contains('herb') || 
      lowerName.contains('spice') || lowerName.contains('garlic') || lowerName.contains('ginger')) {
    return 'spice';
  }
  
  // Default category
  return 'other';
}

// Stream of public recipes (for discovery)
final publicRecipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final stream = SupabaseService.client
      .from('recipes')
      .stream(primaryKey: ['id'])
      .eq('visibility', 'public')
      .order('created_at', ascending: false)
      .map((rows) => rows.map((m) => Recipe.fromMap(m)).toList());
  return stream;
});

// Provider to get author information for a specific user ID
final authorProfileProvider = FutureProvider.family<Map<String, String?>?, String>((ref, authorId) async {
  try {
    // Primary: Get from profiles table (preferred source)
    final profileResponse = await SupabaseService.client
        .from('profiles')
        .select('handle, display_name')
        .eq('user_id', authorId)
        .maybeSingle();
    
    if (profileResponse != null) {
      return {
        'handle': profileResponse['handle'] as String?,
        'display_name': profileResponse['display_name'] as String?,
      };
    }
    
    // Fallback: Get from users table if profile doesn't exist
    final userResponse = await SupabaseService.client
        .from('users')
        .select('display_name')
        .eq('id', authorId)
        .maybeSingle();
    
    if (userResponse != null) {
      return {
        'handle': null,
        'display_name': userResponse['display_name'] as String?,
      };
    }
    
    return null;
  } catch (e) {
    logDebug('Failed to fetch author info for $authorId: $e');
    return null;
  }
});

// Provider to check if a recipe is saved by the current user
final isRecipeSavedProvider = FutureProvider.family<bool, String>((ref, recipeId) async {
  final client = SupabaseService.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return false;

  try {
    final response = await client
        .from('recipe_saves')
        .select('recipe_id')
        .eq('user_id', uid)
        .eq('recipe_id', recipeId)
        .maybeSingle();
    
    return response != null;
  } catch (e) {
    logDebug('Failed to check if recipe is saved: $e');
    return false;
  }
});

// Provider to save a recipe
final saveRecipeProvider = FutureProvider.family<void, String>((ref, recipeId) async {
  final client = SupabaseService.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    throw Exception('Not signed in');
  }

  try {
    // Check if already saved first
    final existing = await client
        .from('recipe_saves')
        .select('user_id')
        .eq('user_id', uid)
        .eq('recipe_id', recipeId)
        .maybeSingle();
    
    if (existing != null) {
      logDebug('Recipe $recipeId is already saved by user $uid');
      return; // Already saved, no error
    }
    
    await client.from('recipe_saves').insert({
      'user_id': uid,
      'recipe_id': recipeId,
    });
    logDebug('Successfully saved recipe $recipeId for user $uid');
  } catch (e) {
    logDebug('Failed to save recipe $recipeId: $e');
    // Provide more detailed error message
    if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
      logDebug('Recipe is already saved (duplicate key)');
      return; // Already saved, treat as success
    }
    rethrow;
  }
});

// Provider to unsave a recipe
final unsaveRecipeProvider = FutureProvider.family<void, String>((ref, recipeId) async {
  final client = SupabaseService.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    throw Exception('Not signed in');
  }

  try {
    await client
        .from('recipe_saves')
        .delete()
        .eq('user_id', uid)
        .eq('recipe_id', recipeId);
  } catch (e) {
    logDebug('Failed to unsave recipe: $e');
    rethrow;
  }
});

// Provider to update recipe visibility
final updateRecipeVisibilityProvider = FutureProvider.family<void, ({
  String recipeId,
  RecipeVisibility visibility,
})>((ref, args) async {
  final client = SupabaseService.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    throw Exception('Not signed in');
  }

  try {
    await client
        .from('recipes')
        .update({'visibility': args.visibility.name})
        .eq('id', args.recipeId)
        .eq('author_id', uid); // Ensure user can only update their own recipes
  } catch (e) {
    logDebug('Failed to update recipe visibility: $e');
    rethrow;
  }
});

// Stream of current user's recipes only
final userRecipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(<Recipe>[]);
  }

  final stream = SupabaseService.client
      .from('recipes')
      .stream(primaryKey: ['id'])
      .eq('author_id', user.id)
      .order('created_at', ascending: false)
      .map((rows) => rows.map((m) => Recipe.fromMap(m)).toList());
  return stream;
});

// Stream of user's own created recipes only
final userOwnRecipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(<Recipe>[]);
  }

  return SupabaseService.client
      .from('recipes')
      .stream(primaryKey: ['id'])
      .eq('author_id', user.id)
      .order('created_at', ascending: false)
      .map((rows) => rows.map((m) => Recipe.fromMap(m)).toList());
});

// Refresh trigger for saved recipes
final savedRecipesRefreshProvider = StateProvider<int>((ref) => 0);

// Stream of user's saved recipes
final userSavedRecipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  // Watch the refresh trigger to force refresh when needed
  ref.watch(savedRecipesRefreshProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(<Recipe>[]);
  }

  return SupabaseService.client
      .from('recipe_saves')
      .stream(primaryKey: ['user_id', 'recipe_id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((saves) {
        logDebug('Recipe saves stream updated: ${saves.length} saves');
        return saves.map((save) => save['recipe_id'] as String).toList();
      })
      .asyncMap((recipeIds) async {
        logDebug('Loading ${recipeIds.length} saved recipes');
        if (recipeIds.isEmpty) return <Recipe>[];
        
        final recipes = await SupabaseService.client
            .from('recipes')
            .select('*')
            .inFilter('id', recipeIds);
            // Removed .eq('visibility', 'public') to allow loading any saved recipe
        
        // Maintain the order from recipe_saves
        final recipeMap = <String, Recipe>{};
        for (final r in recipes) {
          try {
            recipeMap[r['id'] as String] = Recipe.fromMap(r);
          } catch (e) {
            logDebug('Error parsing recipe ${r['id']}: $e');
          }
        }
        
        // Filter out any recipes that failed to parse
        final validRecipes = recipeIds
            .where((id) => recipeMap.containsKey(id))
            .map((id) => recipeMap[id]!)
            .toList();
        
        logDebug('Successfully loaded ${validRecipes.length} saved recipes');
        return validRecipes;
      });
});

// Combined stream of user's own recipes + saved recipes for "My Recipe" tab
final myRecipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final ownRecipesAsync = ref.watch(userOwnRecipesStreamProvider);
  final savedRecipesAsync = ref.watch(userSavedRecipesStreamProvider);

  return Stream.value(ownRecipesAsync.when(
    data: (ownRecipes) => savedRecipesAsync.when(
      data: (savedRecipes) {
        // Combine and deduplicate recipes (in case user saved their own recipe)
        final allRecipes = [...ownRecipes, ...savedRecipes];
        final uniqueRecipes = <String, Recipe>{};
        for (final recipe in allRecipes) {
          uniqueRecipes[recipe.id] = recipe;
        }
        return uniqueRecipes.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
      loading: () => ownRecipes,
      error: (_, __) => ownRecipes,
    ),
    loading: () => savedRecipesAsync.when(
      data: (savedRecipes) => savedRecipes,
      loading: () => <Recipe>[],
      error: (_, __) => <Recipe>[],
    ),
    error: (_, __) => savedRecipesAsync.when(
      data: (savedRecipes) => savedRecipes,
      loading: () => <Recipe>[],
      error: (_, __) => <Recipe>[],
    ),
  ));
});

// Keep the old provider name for backward compatibility
final recipesStreamProvider = myRecipesStreamProvider;

final addRecipeProvider = FutureProvider.family<void, ({
  String title, 
  String? description,
  String? photoUrl, 
  ProteinPreference protein, 
  String? cuisine,
  int servings,
  int? prepTimeMin,
  int? cookTimeMin,
  RecipeVisibility visibility,
  List<IngredientInput> ingredients
})>((ref, args) async {
  final client = SupabaseService.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    throw Exception('Not signed in');
  }
  
  // Ensure user exists in public.users table (for legacy constraint)
  await client.from('users').upsert({
    'id': uid,
    'display_name': client.auth.currentUser?.userMetadata?['full_name'] ?? 
                   client.auth.currentUser?.email?.split('@')[0],
  });
  
  // Note: Profiles are handled separately in the auth flow
  // Don't try to upsert profiles here as it may cause RLS issues
  
  // Get supported protein values from database (with fallback)
  final supportedValuesAsync = ref.read(supportedProteinValuesProvider);
  final supportedValues = await supportedValuesAsync.when(
    data: (values) => values,
    loading: () => null, // Use null to allow all values (after enum update)
    error: (_, __) => null,
  );
  
  // Map protein preference to database-compatible values
  final proteinValue = _mapProteinForDatabase(args.protein, supportedValues);
  
  final insert = <String, dynamic>{
    'title': args.title,
    'user_id': uid, // Legacy field - now guaranteed to exist in users table
    'author_id': uid, // New multi-user field - references auth.users(id)
    'description': args.description,
    'protein': proteinValue, // May be null for unsupported values
    'cuisine': args.cuisine,
    'servings': args.servings,
    'prep_time_min': args.prepTimeMin,
    'cook_time_min': args.cookTimeMin,
    'visibility': args.visibility.name,
    'language': 'en',
  };
  
  if (args.photoUrl != null && args.photoUrl!.isNotEmpty) {
    insert['image_url'] = args.photoUrl;
  }
  
  final recipe = await client.from('recipes').insert(insert).select('id').single();
  final recipeId = recipe['id'] as String;

  for (final ing in args.ingredients.where((i) => i.name.trim().isNotEmpty)) {
    final name = ing.name.trim();

    // 1) Find ingredient by name (case-insensitive). If not exists, create it.
    Map<String, dynamic>? ingredient;
    final found = await client
        .from('ingredients')
        .select('id, default_unit')
        .ilike('name', name)
        .maybeSingle();

    if (found != null) {
      ingredient = found;
    } else {
      // Auto-categorize ingredient based on name
      final category = _categorizeIngredient(name);
      ingredient = await client
          .from('ingredients')
          .insert({
            'name': name,
            'default_unit': ing.unit,
            'category': category,
          })
          .select('id, default_unit, category')
          .single();
    }

    final ingredientId = ingredient['id'] as String;
    final defaultUnit = ingredient['default_unit'] as String?;

    // 2) Insert into recipe_ingredients using foreign key by id
    await client.from('recipe_ingredients').insert({
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'quantity': ing.qty,
      'unit': ing.unit ?? defaultUnit,
    });
  }
});

final deleteRecipeProvider = FutureProvider.family<void, String>((ref, recipeId) async {
  final client = SupabaseService.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    throw Exception('Not signed in');
  }
  
  // First delete all recipe ingredients
  await client.from('recipe_ingredients').delete().eq('recipe_id', recipeId);
  
  // Then delete the recipe (only if owned by current user)
  await client
      .from('recipes')
      .delete()
      .eq('id', recipeId)
      .eq('author_id', uid);
});

final recipeIngredientsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, recipeId) async {
  final client = SupabaseService.client;
  
  final response = await client
      .from('recipe_ingredients')
      .select('''
        quantity,
        unit,
        note,
        ingredients!inner(name, default_unit, category)
      ''')
      .eq('recipe_id', recipeId);
  
  return response;
});

// Provider to search ingredients by name (for autocomplete) - now bilingual!
final searchIngredientsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return [];
  }
  
  final client = SupabaseService.client;
  final searchTerm = query.trim();
  
  try {
    // First, search ingredient_terms table for bilingual support
    final termsResponse = await client
        .from('ingredient_terms')
        .select('''
          term,
          locale,
          is_primary,
          weight,
          ingredients!inner(
            id,
            name,
            category,
            default_unit
          )
        ''')
        .or('term.ilike.%$searchTerm%,term_norm.ilike.%${searchTerm.toLowerCase()}%')
        .order('is_primary', ascending: false)
        .order('weight', ascending: false)
        .order('term')
        .limit(20);
    
    // Group by ingredient to avoid duplicates and return the best match for each ingredient
    final Map<String, Map<String, dynamic>> uniqueIngredients = {};
    
    for (final row in termsResponse) {
      final ingredient = row['ingredients'] as Map<String, dynamic>;
      final ingredientId = ingredient['id'] as String;
      
      if (!uniqueIngredients.containsKey(ingredientId)) {
        uniqueIngredients[ingredientId] = {
          'id': ingredient['id'],
          'name': ingredient['name'], // Always use original ingredient name for display
          'category': ingredient['category'],
          'default_unit': ingredient['default_unit'],
          'matched_term': row['term'], // The term that matched the search
          'locale': row['locale'],
          'is_primary': row['is_primary'],
        };
      }
    }
    
    // Also search ingredients table directly for English names that might not be in ingredient_terms
    final ingredientsResponse = await client
        .from('ingredients')
        .select('id, name, category, default_unit')
        .or('name.ilike.%$searchTerm%,name_norm.ilike.%${searchTerm.toLowerCase()}%')
        .order('name')
        .limit(20);
    
    // Add ingredients that aren't already found in terms search
    for (final ingredient in ingredientsResponse) {
      final ingredientId = ingredient['id'] as String;
      
      if (!uniqueIngredients.containsKey(ingredientId)) {
        uniqueIngredients[ingredientId] = {
          'id': ingredient['id'],
          'name': ingredient['name'],
          'category': ingredient['category'],
          'default_unit': ingredient['default_unit'],
          'matched_term': ingredient['name'],
          'locale': 'en',
          'is_primary': true,
        };
      }
    }
    
    return uniqueIngredients.values.toList();
  } catch (e) {
    logDebug('Error searching ingredients: $e');
    // Final fallback to simple ingredients search
    try {
      final fallbackResponse = await client
          .from('ingredients')
          .select('id, name, category, default_unit')
          .ilike('name', '%$searchTerm%')
          .order('name')
          .limit(10);
      
      return fallbackResponse.map((ingredient) => {
        ...ingredient,
        'matched_term': ingredient['name'],
        'locale': 'en',
        'is_primary': true,
      }).toList();
    } catch (fallbackError) {
      logDebug('Fallback search also failed: $fallbackError');
      return [];
    }
  }
});

// Provider to search recipes by ingredient (bilingual search)
final searchRecipesByIngredientProvider = FutureProvider.family<List<Recipe>, String>((ref, searchTerm) async {
  if (searchTerm.trim().isEmpty) {
    return [];
  }
  
  final client = SupabaseService.client;
  
  try {
    // Use the new bilingual search function
    final response = await client
        .rpc('search_recipes_by_ingredient', params: {'q': searchTerm.trim()});
    
    final recipeIds = response.map((data) => data['recipe_id'] as String).toList();
    
    if (recipeIds.isEmpty) return [];
    
    final recipes = await client
        .from('recipes')
        .select('*')
        .inFilter('id', recipeIds)
        .eq('visibility', 'public'); // Only show public recipes in search
    
    return recipes.map((data) => Recipe.fromMap(data)).toList();
  } catch (e) {
    logDebug('Error searching recipes by ingredient: $e');
    return [];
  }
});

final updateRecipeProvider = FutureProvider.family<void, ({
  String recipeId,
  String title,
  String? photoUrl,
  ProteinPreference protein,
  List<IngredientInput> ingredients,
})>((ref, args) async {
  final client = SupabaseService.client;
  
  // Get supported protein values from database (with fallback)
  final supportedValuesAsync = ref.read(supportedProteinValuesProvider);
  final supportedValues = await supportedValuesAsync.when(
    data: (values) => values,
    loading: () => null, // Use null to allow all values (after enum update)
    error: (_, __) => null,
  );
  
  // Update the recipe
  // Map protein preference to database-compatible values dynamically
  final updateData = <String, dynamic>{
    'title': args.title,
    if (args.photoUrl != null) 'image_url': args.photoUrl,
  };
  
  // Map protein value using dynamically queried enum values
  final proteinValue = _mapProteinForDatabase(args.protein, supportedValues);
  if (proteinValue != null) {
    updateData['protein'] = proteinValue;
  } else {
    // For unsupported values, set to null
    updateData['protein'] = null;
  }
  
  await client
      .from('recipes')
      .update(updateData)
      .eq('id', args.recipeId);
  
  // Delete existing ingredients
  await client
      .from('recipe_ingredients')
      .delete()
      .eq('recipe_id', args.recipeId);
  
  // Add updated ingredients
  for (final ing in args.ingredients.where((i) => i.name.trim().isNotEmpty)) {
    final name = ing.name.trim();
    
    // Find or create ingredient
    Map<String, dynamic>? ingredient;
    final found = await client
        .from('ingredients')
        .select('id, default_unit')
        .ilike('name', name)
        .maybeSingle();
    
    if (found != null) {
      ingredient = found;
    } else {
      // Auto-categorize ingredient based on name
      final category = _categorizeIngredient(name);
      ingredient = await client
          .from('ingredients')
          .insert({
            'name': name,
            'default_unit': ing.unit,
            'category': category,
          })
          .select('id, default_unit, category')
          .single();
    }
    
    final ingredientId = ingredient['id'] as String;
    final defaultUnit = ingredient['default_unit'] as String?;
    
    // Insert into recipe_ingredients
    await client.from('recipe_ingredients').insert({
      'recipe_id': args.recipeId,
      'ingredient_id': ingredientId,
      'quantity': ing.qty,
      'unit': ing.unit ?? defaultUnit,
    });
  }
});

// Provider for translation statistics
final translationStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await TranslationService.getTranslationStats();
});

// Provider for all translations
final translationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await TranslationService.getAllTranslations();
});

// Provider for adding new ingredients with auto-translation
final addIngredientWithTranslationProvider = FutureProvider.family<String, Map<String, dynamic>>((ref, ingredientData) async {
  try {
    final client = SupabaseService.client;
    
    // Add the ingredient
    final response = await client
        .from('ingredients')
        .insert({
          'name': ingredientData['name'],
          'category': ingredientData['category'],
          'default_unit': ingredientData['default_unit'],
          'created_by': ingredientData['created_by'],
        })
        .select('id, name')
        .single();
    
    // The trigger will automatically add Chinese translation if available
    return response['name'];
  } catch (e) {
    logDebug('Error adding ingredient: $e');
    rethrow;
  }
});
