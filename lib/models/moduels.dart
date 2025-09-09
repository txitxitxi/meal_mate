class Recipe {
  final String id;
  final String title;
  final String? photoUrl;

  Recipe({required this.id, required this.title, this.photoUrl});

  factory Recipe.fromMap(Map<String, dynamic> m) => Recipe(
        id: m['id'] as String,
        title: m['title'] as String,
        photoUrl: m['photo_url'] as String?,
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
  StoreItem({required this.id, required this.storeId, required this.ingredientName});
  factory StoreItem.fromMap(Map<String, dynamic> m) => StoreItem(
        id: m['id'] as String,
        storeId: m['store_id'] as String,
        ingredientName: m['ingredient_name'] as String,
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
