enum ProteinPreference { none, chicken, beef, pork, fish, vegetarian, vegan }

enum RecipeVisibility { public, unlisted, private }

class Recipe {
  final String id;
  final String userId; // Legacy field - still required by schema
  final String title;
  final String? description;
  final ProteinPreference protein;
  final String? cuisine;
  final int servings;
  final int? prepTimeMin;
  final int? cookTimeMin;
  final String? imageUrl;
  final bool isPublic; // Legacy field, keep for compatibility
  final DateTime createdAt;
  final String? authorId;
  final RecipeVisibility visibility;
  final String language;
  final String? forksFrom;

  const Recipe({
    required this.id,
    required this.userId, // Required by schema
    required this.title,
    this.description,
    this.protein = ProteinPreference.none,
    this.cuisine,
    this.servings = 2,
    this.prepTimeMin,
    this.cookTimeMin,
    this.imageUrl,
    this.isPublic = false,
    required this.createdAt,
    this.authorId,
    this.visibility = RecipeVisibility.public,
    this.language = 'en',
    this.forksFrom,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      userId: map['user_id'] as String, // Required by schema
      title: map['title'] as String,
      description: map['description'] as String?,
      protein: _parseProteinPreference(map['protein']),
      cuisine: map['cuisine'] as String?,
      servings: map['servings'] as int? ?? 2,
      prepTimeMin: map['prep_time_min'] as int?,
      cookTimeMin: map['cook_time_min'] as int?,
      imageUrl: map['image_url'] as String?,
      isPublic: map['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      authorId: map['author_id'] as String?,
      visibility: _parseVisibility(map['visibility']),
      language: map['language'] as String? ?? 'en',
      forksFrom: map['forks_from'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'protein': protein.name,
      'cuisine': cuisine,
      'servings': servings,
      'prep_time_min': prepTimeMin,
      'cook_time_min': cookTimeMin,
      'image_url': imageUrl,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'author_id': authorId,
      'visibility': visibility.name,
      'language': language,
      'forks_from': forksFrom,
    };
  }

  Recipe copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ProteinPreference? protein,
    String? cuisine,
    int? servings,
    int? prepTimeMin,
    int? cookTimeMin,
    String? imageUrl,
    bool? isPublic,
    DateTime? createdAt,
    String? authorId,
    RecipeVisibility? visibility,
    String? language,
    String? forksFrom,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      protein: protein ?? this.protein,
      cuisine: cuisine ?? this.cuisine,
      servings: servings ?? this.servings,
      prepTimeMin: prepTimeMin ?? this.prepTimeMin,
      cookTimeMin: cookTimeMin ?? this.cookTimeMin,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      visibility: visibility ?? this.visibility,
      language: language ?? this.language,
      forksFrom: forksFrom ?? this.forksFrom,
    );
  }

  static ProteinPreference _parseProteinPreference(dynamic value) {
    if (value == null) return ProteinPreference.none;
    try {
      return ProteinPreference.values.firstWhere(
        (e) => e.name == value.toString(),
        orElse: () => ProteinPreference.none,
      );
    } catch (e) {
      return ProteinPreference.none;
    }
  }

  static RecipeVisibility _parseVisibility(dynamic value) {
    if (value == null) return RecipeVisibility.public;
    try {
      return RecipeVisibility.values.firstWhere(
        (e) => e.name == value.toString(),
        orElse: () => RecipeVisibility.public,
      );
    } catch (e) {
      return RecipeVisibility.public;
    }
  }
}

class RecipeIngredient {
  final String recipeId;
  final String ingredientId;
  final double quantity;
  final String? unit;
  final String? note;

  const RecipeIngredient({
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    this.unit,
    this.note,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      recipeId: map['recipe_id'] as String,
      ingredientId: map['ingredient_id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String?,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'quantity': quantity,
      'unit': unit,
      'note': note,
    };
  }
}

class Ingredient {
  final String id;
  final String name;
  final String? defaultUnit;
  final String? category;
  final String? createdBy;
  final DateTime createdAt;

  const Ingredient({
    required this.id,
    required this.name,
    this.defaultUnit,
    this.category,
    this.createdBy,
    required this.createdAt,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      defaultUnit: map['default_unit'] as String?,
      category: map['category'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'default_unit': defaultUnit,
      'category': category,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
