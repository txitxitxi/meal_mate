import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

final recipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final stream = SupabaseService.client
      .from('recipes')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((rows) => rows.map((m) => Recipe.fromMap(m)).toList());
  return stream;
});

final addRecipeProvider = FutureProvider.family<void, ({String title, String? photoUrl, List<IngredientInput> ingredients})>((ref, args) async {
  final client = SupabaseService.client;
  final recipe = await client.from('recipes').insert({
    'title': args.title,
    'photo_url': args.photoUrl,
  }).select('id').single();

  final recipeId = recipe['id'] as String;

  for (final ing in args.ingredients.where((i) => i.name.trim().isNotEmpty)) {
    await client.from('recipe_ingredients').insert({
      'recipe_id': recipeId,
      'ingredient_name': ing.name.trim(),
      'qty': ing.qty,
      'unit': ing.unit,
    });
  }
});
