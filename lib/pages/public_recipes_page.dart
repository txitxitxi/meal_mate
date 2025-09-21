import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recipe_providers.dart';
import '../models/recipe.dart';

class PublicRecipesPage extends ConsumerStatefulWidget {
  const PublicRecipesPage({super.key});

  @override
  ConsumerState<PublicRecipesPage> createState() => _PublicRecipesPageState();
}

class _PublicRecipesPageState extends ConsumerState<PublicRecipesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isChinese(String text) {
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    // Use bilingual search if there's a search query, otherwise show all public recipes
    final recipesAsync = _searchQuery.isNotEmpty 
        ? ref.watch(searchRecipesByIngredientProvider(_searchQuery))
        : ref.watch(publicRecipesStreamProvider);
    
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by ingredient (e.g., "beef" or "牛肉")...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          // Recipes List
          Expanded(
            child: recipesAsync.when(
              data: (recipes) {
                // No need to filter since searchRecipesByIngredientProvider already does the filtering
                final filteredRecipes = recipes;

                if (filteredRecipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.public : Icons.search_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'No public recipes available' 
                                  : 'No recipes found for "$_searchQuery"',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            if (_searchQuery.isNotEmpty && _isChinese(_searchQuery)) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '中文',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Check back later for community recipes' 
                              : 'Try a different search term',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    // Refresh the public recipes
                    ref.invalidate(publicRecipesStreamProvider);
                    // Wait a bit for the refresh to complete
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: filteredRecipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final r = filteredRecipes[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: r.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(r.imageUrl!, width: 48, height: 48, fit: BoxFit.cover),
                                )
                              : SizedBox(width: 48, height: 48, child: Icon(Icons.image_not_supported, size: 20)),
                          title: Text(r.title, style: const TextStyle(fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Consumer(
                                builder: (context, ref, child) {
                                  if (r.authorId != null) {
                                    final authorAsync = ref.watch(authorProfileProvider(r.authorId!));
                                    return authorAsync.when(
                                      data: (authorInfo) {
                                        final authorName = _getAuthorDisplayName(r, authorInfo);
                                        return Text('By $authorName', style: TextStyle(color: Colors.grey[600], fontSize: 11));
                                      },
                                      loading: () => Text('By Community', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                      error: (error, __) => Text('By Community', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                    );
                                  }
                                  return Text('By Community', style: TextStyle(color: Colors.grey[600], fontSize: 11));
                                },
                              ),
                              if (r.protein != null && r.protein!.name.toLowerCase() != 'none')
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Chip(
                                    label: Text(r.protein!.name.toUpperCase()),
                                    backgroundColor: Colors.green.shade100,
                                    labelStyle: TextStyle(color: Colors.green.shade700, fontSize: 9),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            // Show recipe details
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(r.title),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (r.imageUrl != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(r.imageUrl!, width: 200, height: 150, fit: BoxFit.cover),
                                        ),
                                      const SizedBox(height: 16),
                                      const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final ingredientsAsync = ref.watch(recipeIngredientsProvider(r.id));
                                          return ingredientsAsync.when(
                                            data: (ingredients) {
                                              if (ingredients.isEmpty) {
                                                return const Text('No ingredients found');
                                              }
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: ingredients.map((ing) {
                                                  final ingredientName = ing['ingredients']?['name'] ?? 'Unknown';
                                                  final quantity = ing['quantity'];
                                                  final unit = ing['unit'] ?? '';
                                                  final note = ing['note'] ?? '';
                                                  final category = ing['ingredients']?['category'] ?? '';
                                                  
                                                  // Handle quantity - it could be numeric, int, or string
                                                  String quantityText = '';
                                                  if (quantity != null) {
                                                    if (quantity is num) {
                                                      quantityText = quantity.toString();
                                                    } else if (quantity is String) {
                                                      quantityText = quantity;
                                                    }
                                                  }
                                                  
                                                  final hasQuantity = quantityText.isNotEmpty;
                                                  final hasUnit = unit.isNotEmpty;
                                                  final hasNote = note.isNotEmpty;
                                                  
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('• $ingredientName${hasQuantity ? ' - $quantityText${hasUnit ? ' $unit' : ''}' : ''}'),
                                                        if (hasNote) 
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 16, top: 2),
                                                            child: Text('  Note: $note', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                                          ),
                                                        if (category.isNotEmpty)
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 16, top: 1),
                                                            child: Text('  Category: $category', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            },
                                            loading: () => const CircularProgressIndicator(),
                                            error: (error, stack) => Text('Error loading ingredients: $error'),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final isSavedAsync = ref.watch(isRecipeSavedProvider(r.id));
                                      return isSavedAsync.when(
                                        data: (isSaved) => FilledButton.icon(
                                          onPressed: () async {
                                            try {
                                              if (isSaved) {
                                                await ref.read(unsaveRecipeProvider(r.id).future);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Recipe unsaved')),
                                                );
                                              } else {
                                                await ref.read(saveRecipeProvider(r.id).future);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Recipe saved to your collection!')),
                                                );
                                              }
                                              // Refresh the saved status
                                              ref.invalidate(isRecipeSavedProvider(r.id));
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed to ${isSaved ? 'unsave' : 'save'} recipe: $e')),
                                              );
                                            }
                                          },
                                          icon: Icon(isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
                                          label: Text(isSaved ? 'Unsave' : 'Save Recipe'),
                                        ),
                                        loading: () => FilledButton.icon(
                                          onPressed: null, // Disabled during loading
                                          icon: const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          label: const Text('Save Recipe'),
                                        ),
                                        error: (_, __) => FilledButton.icon(
                                          onPressed: () async {
                                            try {
                                              await ref.read(saveRecipeProvider(r.id).future);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Recipe saved to your collection!')),
                                              );
                                              ref.invalidate(isRecipeSavedProvider(r.id));
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed to save recipe: $e')),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.bookmark_add),
                                          label: const Text('Save Recipe'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getAuthorDisplayName(Recipe recipe, Map<String, String?>? authorInfo) {
    // Use the actual author information if available
    if (authorInfo != null) {
      final displayName = authorInfo['display_name'];
      final handle = authorInfo['handle'];
      
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
      if (handle != null && handle.isNotEmpty) {
        return '@$handle';
      }
    }
    
    // If we have an author_id but no profile info, show a shortened version of the ID
    if (recipe.authorId != null && recipe.authorId!.isNotEmpty) {
      // Show last 8 characters of the UUID for readability
      final shortId = recipe.authorId!.length > 8 
          ? recipe.authorId!.substring(recipe.authorId!.length - 8)
          : recipe.authorId!;
      return 'User $shortId';
    }
    
    // Fallback to "Community" if no author info is available
    return 'Community';
  }
}