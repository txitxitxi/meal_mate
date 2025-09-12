import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moduels.dart';
import '../services/supabase_service.dart';

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

final recipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final stream = SupabaseService.client
      .from('recipes')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((rows) => rows.map((m) => Recipe.fromMap(m)).toList());
  return stream;
});

final addRecipeProvider = FutureProvider.family<void, ({String title, String? photoUrl, String protein, List<IngredientInput> ingredients})>((ref, args) async {
  final client = SupabaseService.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    throw Exception('Not signed in');
  }
  final insert = <String, dynamic>{
    'title': args.title,
    'user_id': uid,
    'protein': args.protein,
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
      ingredient = found as Map<String, dynamic>;
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
  
  // First delete all recipe ingredients
  await client.from('recipe_ingredients').delete().eq('recipe_id', recipeId);
  
  // Then delete the recipe
  await client.from('recipes').delete().eq('id', recipeId);
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

final updateRecipeProvider = FutureProvider.family<void, ({
  String recipeId,
  String title,
  String? photoUrl,
  List<IngredientInput> ingredients,
})>((ref, args) async {
  final client = SupabaseService.client;
  
  // Update the recipe
  await client
      .from('recipes')
      .update({
        'title': args.title,
        if (args.photoUrl != null) 'image_url': args.photoUrl,
      })
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
      ingredient = found as Map<String, dynamic>;
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
