class Recipe {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? cuisine;
  final String? protein;
  final int? servings;
  final int? prepTimeMin;
  final int? cookTimeMin;
  final bool isPublic;
  final DateTime? createdAt;

  Recipe({
    required this.id, 
    required this.title, 
    this.description,
    this.imageUrl,
    this.cuisine,
    this.protein,
    this.servings,
    this.prepTimeMin,
    this.cookTimeMin,
    this.isPublic = false,
    this.createdAt,
  });

  factory Recipe.fromMap(Map<String, dynamic> m) => Recipe(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        imageUrl: m['image_url'] as String?,
        cuisine: m['cuisine'] as String?,
        protein: m['protein'] as String?,
        servings: m['servings'] as int?,
        prepTimeMin: m['prep_time_min'] as int?,
        cookTimeMin: m['cook_time_min'] as int?,
        isPublic: (m['is_public'] as bool?) ?? false,
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
      );
}

class IngredientInput {
  String name;
  String? unit;
  double? qty;
  IngredientInput({this.name = '', this.unit, this.qty});
}

class Store {
  final String id;
  final String name;
  final bool isDefault;
  Store({required this.id, required this.name, required this.isDefault});
  factory Store.fromMap(Map<String, dynamic> m) => Store(
        id: m['id'] as String,
        name: m['name'] as String,
        isDefault: (m['is_default'] as bool?) ?? false,
      );
}

class StoreItem {
  final String id;
  final String storeId;
  final String ingredientName;
  final double? price;
  final String? aisle;
  final String? availability;
  final bool preferred;
  
  StoreItem({
    required this.id, 
    required this.storeId, 
    required this.ingredientName,
    this.price,
    this.aisle,
    this.availability,
    this.preferred = false,
  });
  
  factory StoreItem.fromMap(Map<String, dynamic> m) => StoreItem(
        id: m['id'] as String,
        storeId: m['store_id'] as String,
        ingredientName: m['ingredients']?['name'] as String? ?? 'Unknown',
        price: (m['price'] as num?)?.toDouble(),
        aisle: m['aisle'] as String?,
        availability: m['availability'] as String?,
        preferred: (m['preferred'] as bool?) ?? false,
      );
}

class WeeklyEntry {
  final DateTime day;
  final Recipe recipe;
  WeeklyEntry({required this.day, required this.recipe});
}

class ShoppingListItem {
  final String id;
  final String ingredientName;
  final String? storeId;
  final String? storeName;
  final String? unit;
  final double? qty;
  final bool purchased;

  ShoppingListItem({
    required this.id,
    required this.ingredientName,
    this.storeId,
    this.storeName,
    this.unit,
    this.qty,
    required this.purchased,
  });

  factory ShoppingListItem.fromMap(Map<String, dynamic> m) => ShoppingListItem(
        id: m['id'] as String,
        ingredientName: m['ingredient_name'] as String,
        storeId: m['store_id'] as String?,
        storeName: m['store_name'] as String?,
        unit: m['unit'] as String?,
        qty: (m['qty'] as num?)?.toDouble(),
        purchased: (m['purchased'] as bool?) ?? false,
      );
}
