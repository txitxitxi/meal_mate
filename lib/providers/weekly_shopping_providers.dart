import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

final weeklyPlanProvider = StreamProvider<List<WeeklyEntry>>((ref) async* {
  final stream = SupabaseService.client
      .from('weekly_plans_view')
      .stream(primaryKey: ['day', 'recipe_id'])
      .order('day')
      .map((rows) => rows
          .map((m) => WeeklyEntry(
                day: DateTime.parse(m['day'] as String),
                recipe: Recipe(
                  id: m['recipe_id'] as String,
                  title: m['title'] as String,
                  photoUrl: m['photo_url'] as String?,
                ),
              ))
          .toList());
  yield* stream;
});

final generatePlanProvider = FutureProvider<void>((ref) async {
  try {
    await SupabaseService.client.rpc('generate_weekly_plan');
  } catch (_) {
    final recipes = await SupabaseService.client
        .from('recipes')
        .select('id, title, photo_url')
        .order('created_at')
        .limit(7);

    final today = DateTime.now();
    for (int i = 0; i < recipes.length; i++) {
      final day = DateTime(today.year, today.month, today.day).add(Duration(days: i));
      await SupabaseService.client.from('weekly_plans').upsert({
        'day': day.toIso8601String(),
        'recipe_id': recipes[i]['id'],
      }, onConflict: 'day');
    }
  }
});

final shoppingListProvider = StreamProvider<List<ShoppingListItem>>((ref) {
  return SupabaseService.client
      .from('shopping_list_view')
      .stream(primaryKey: ['id'])
      .order('store_name', ascending: true)
      .map((rows) => rows.map((m) => ShoppingListItem.fromMap(m)).toList());
});

final togglePurchasedProvider = FutureProvider.family<void, String>((ref, itemId) async {
  final client = SupabaseService.client;
  final current = await client.from('shopping_list_items').select('purchased').eq('id', itemId).single();
  final next = !(current['purchased'] as bool? ?? false);
  await client.from('shopping_list_items').update({'purchased': next}).eq('id', itemId);
});
