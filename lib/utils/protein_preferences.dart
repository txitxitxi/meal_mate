class ProteinPreferences {
  // Single source of truth for all protein preference options
  static const List<String> all = [
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
  ];

  // For meal planning, we use 'any' instead of 'none'
  static const List<String> mealPlanning = [
    'any',
    'chicken',
    'beef',
    'egg',
    'fish',
    'pork',
    'seafood',
    'tofu',
    'vegetarian',
    'vegan',
  ];

  // Mapping for ingredient patterns (used in meal plan generation)
  static const Map<String, List<String>> ingredientPatterns = {
    'chicken': ['chicken', 'turkey', 'duck'],
    'beef': ['beef', 'steak', 'ground beef'],
    'egg': ['egg', 'eggs'],
    'fish': ['salmon', 'tuna', 'cod', 'fish'],
    'pork': ['pork', 'bacon', 'ham'],
    'seafood': ['shrimp', 'crab', 'lobster', 'scallop'],
    'tofu': ['tofu'],
    'vegetarian': ['bean', 'lentil', 'chickpea', 'tofu', 'cheese', 'milk', 'yogurt', 'almond', 'walnut', 'egg', 'eggs'],
    'vegan': ['bean', 'lentil', 'chickpea', 'tofu', 'almond', 'walnut'],
  };

  // Get all ingredient patterns for 'none' preference
  static List<String> get allIngredientPatterns => [
    'chicken', 'turkey', 'duck', 'beef', 'steak', 'egg', 'eggs', 'pork', 'bacon', 'ham',
    'salmon', 'tuna', 'cod', 'fish', 'shrimp', 'crab', 'lobster', 'tofu',
    'bean', 'lentil', 'chickpea', 'cheese', 'milk', 'yogurt', 'almond', 'walnut'
  ];
}
