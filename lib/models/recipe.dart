class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;

  const Recipe({required this.id, required this.name, required this.ingredients});

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
        id: map['id'] as String,
        name: map['name'] as String,
        ingredients: (map['ingredients'] as List<dynamic>).cast<String>(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'ingredients': ingredients,
      };
}
