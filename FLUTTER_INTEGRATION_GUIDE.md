# Flutter Integration Guide for Bilingual Ingredients

This guide shows how to integrate the new bilingual ingredient search functionality into your Flutter app.

## Overview

The bilingual ingredients system allows users to search for recipes using either English or Chinese ingredient names. The system preserves the original display casing (e.g., "Beef", "Ice Cream") while supporting multiple language aliases.

## Key Components

1. **`ingredients` table**: Original ingredient names with preserved casing
2. **`ingredient_terms` table**: Multilingual aliases and synonyms
3. **`search_recipes_by_ingredient()` function**: Bilingual search across recipes
4. **Helper functions**: For managing aliases and merging duplicates

## Flutter Integration Steps

### 1. Update Recipe Search

Replace your existing ingredient-based recipe search with the new bilingual search function:

```dart
// Before (example)
Future<List<Recipe>> searchRecipesByIngredient(String searchTerm) async {
  final response = await supabase
      .from('recipes')
      .select('''
        *,
        recipe_ingredients!inner(
          ingredient_id,
          ingredients!inner(name)
        )
      ''')
      .ilike('recipe_ingredients.ingredients.name', '%$searchTerm%');
  
  return response.map((data) => Recipe.fromJson(data)).toList();
}

// After (bilingual search)
Future<List<Recipe>> searchRecipesByIngredient(String searchTerm) async {
  final response = await supabase
      .rpc('search_recipes_by_ingredient', {'q': searchTerm});
  
  final recipeIds = response.map((data) => data['recipe_id'] as String).toList();
  
  if (recipeIds.isEmpty) return [];
  
  final recipes = await supabase
      .from('recipes')
      .select('*')
      .in_('id', recipeIds);
  
  return recipes.map((data) => Recipe.fromJson(data)).toList();
}
```

### 2. Update Ingredient Autocomplete/Typeahead

Update your ingredient autocomplete to search across both English and Chinese terms:

```dart
// Enhanced ingredient autocomplete with bilingual support
Future<List<IngredientSuggestion>> searchIngredients(String query) async {
  if (query.trim().isEmpty) return [];
  
  final response = await supabase
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
      .or('term.ilike.%$query%,term_norm.ilike.%${query.toLowerCase()}%')
      .order('is_primary', ascending: false)
      .order('weight', ascending: false)
      .order('term')
      .limit(20);
  
  // Group by ingredient to avoid duplicates
  final Map<String, IngredientSuggestion> suggestions = {};
  
  for (final row in response) {
    final ingredient = row['ingredients'] as Map<String, dynamic>;
    final ingredientId = ingredient['id'] as String;
    
    if (!suggestions.containsKey(ingredientId)) {
      suggestions[ingredientId] = IngredientSuggestion(
        id: ingredientId,
        name: ingredient['name'] as String,
        category: ingredient['category'] as String?,
        defaultUnit: ingredient['default_unit'] as String?,
        displayTerm: row['term'] as String,
        locale: row['locale'] as String?,
        isPrimary: row['is_primary'] as bool,
      );
    }
  }
  
  return suggestions.values.toList();
}

class IngredientSuggestion {
  final String id;
  final String name;           // Original name (e.g., "Beef")
  final String? category;
  final String? defaultUnit;
  final String displayTerm;    // The term that matched (e.g., "牛肉" or "Beef")
  final String? locale;
  final bool isPrimary;
  
  IngredientSuggestion({
    required this.id,
    required this.name,
    this.category,
    this.defaultUnit,
    required this.displayTerm,
    this.locale,
    required this.isPrimary,
  });
}
```

### 3. Update Ingredient Display

Keep using the original ingredient names for consistent display:

```dart
// In your recipe ingredient widgets
class RecipeIngredientTile extends StatelessWidget {
  final RecipeIngredient recipeIngredient;
  
  const RecipeIngredientTile({required this.recipeIngredient});
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(recipeIngredient.ingredient.name), // Use original name
      subtitle: Text('${recipeIngredient.quantity} ${recipeIngredient.unit}'),
    );
  }
}
```

### 4. Add Ingredient Alias Management (Optional)

If you want to allow users to add new aliases for existing ingredients:

```dart
// Add new ingredient alias
Future<void> addIngredientAlias({
  required String ingredientId,
  required String term,
  String? locale,
  bool isPrimary = false,
  int weight = 1,
}) async {
  await supabase.rpc('add_ingredient_alias', {
    'p_ingredient_id': ingredientId,
    'p_term': term,
    'p_locale': locale,
    'p_is_primary': isPrimary,
    'p_weight': weight,
  });
}

// Usage example
await addIngredientAlias(
  ingredientId: 'beef-ingredient-id',
  term: '牛肉',
  locale: 'zh',
  isPrimary: true,
  weight: 10,
);
```

### 5. Update Search UI

Enhance your search UI to show when results match different languages:

```dart
class BilingualSearchResults extends StatelessWidget {
  final List<Recipe> recipes;
  final String searchTerm;
  
  const BilingualSearchResults({
    required this.recipes,
    required this.searchTerm,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show search term and detected language
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.search),
              SizedBox(width: 8),
              Text('Search results for: "$searchTerm"'),
              if (_isChinese(searchTerm)) ...[
                SizedBox(width: 8),
                Chip(
                  label: Text('中文'),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
            ],
          ),
        ),
        
        // Recipe results
        Expanded(
          child: ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return RecipeCard(recipe: recipes[index]);
            },
          ),
        ),
      ],
    );
  }
  
  bool _isChinese(String text) {
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
  }
}
```

### 6. Update Shopping List Integration

Ensure your shopping list functionality works with the bilingual system:

```dart
// Shopping list should continue using original ingredient names
Future<List<ShoppingListItem>> getShoppingListItems(String mealPlanId) async {
  final response = await supabase
      .from('shopping_list_items')
      .select('''
        *,
        ingredients!inner(
          id,
          name,
          category,
          default_unit
        )
      ''')
      .eq('meal_plan_id', mealPlanId);
  
  return response.map((data) => ShoppingListItem.fromJson(data)).toList();
}
```

## Testing the Integration

### 1. Test Search Functionality

```dart
void testBilingualSearch() async {
  // Test English search
  final englishResults = await searchRecipesByIngredient('beef');
  print('English search results: ${englishResults.length}');
  
  // Test Chinese search
  final chineseResults = await searchRecipesByIngredient('牛肉');
  print('Chinese search results: ${chineseResults.length}');
  
  // Test partial matches
  final partialResults = await searchRecipesByIngredient('chick');
  print('Partial search results: ${partialResults.length}');
}
```

### 2. Test Autocomplete

```dart
void testIngredientAutocomplete() async {
  // Test English autocomplete
  final englishSuggestions = await searchIngredients('beef');
  print('English suggestions: ${englishSuggestions.length}');
  
  // Test Chinese autocomplete
  final chineseSuggestions = await searchIngredients('牛肉');
  print('Chinese suggestions: ${chineseSuggestions.length}');
}
```

## Migration Checklist

- [ ] Run the main migration script in Supabase SQL editor
- [ ] Run the Chinese aliases script
- [ ] Run the test script to verify functionality
- [ ] Update Flutter recipe search to use `search_recipes_by_ingredient()`
- [ ] Update Flutter ingredient autocomplete to search `ingredient_terms`
- [ ] Test search functionality with both English and Chinese terms
- [ ] Test autocomplete functionality
- [ ] Verify existing features still work (shopping lists, meal plans, etc.)

## Performance Considerations

1. **Search Performance**: The trigram indexes make fuzzy search fast
2. **Autocomplete Performance**: Limit results to 20 items for better UX
3. **Caching**: Consider caching frequent searches
4. **Pagination**: For large result sets, implement pagination

## Future Enhancements

1. **More Languages**: Add support for additional languages
2. **User Preferences**: Remember user's preferred language for search
3. **Smart Suggestions**: Suggest related ingredients based on cuisine
4. **Voice Search**: Integrate with speech recognition for hands-free search

## Troubleshooting

### Common Issues

1. **Search returns no results**: Check if Chinese aliases were added for your ingredients
2. **RLS errors**: Ensure you're using the correct role (authenticated vs service_role)
3. **Performance issues**: Check that the trigram indexes were created successfully

### Debug Queries

```sql
-- Check if ingredient_terms table has data
SELECT COUNT(*) FROM public.ingredient_terms;

-- Check if Chinese aliases exist
SELECT COUNT(*) FROM public.ingredient_terms WHERE locale = 'zh';

-- Test search function directly
SELECT * FROM public.search_recipes_by_ingredient('beef');
```

## Support

If you encounter issues, check:
1. Supabase logs for SQL errors
2. Flutter debug console for network errors
3. Database indexes are properly created
4. RLS policies are correctly configured
