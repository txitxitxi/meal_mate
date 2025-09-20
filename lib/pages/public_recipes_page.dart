import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recipe_providers.dart';
import '../models/recipe.dart';

class PublicRecipesPage extends ConsumerWidget {
  const PublicRecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(publicRecipesStreamProvider);
    
    return Scaffold(
      body: recipesAsync.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No public recipes available', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Check back later for community recipes', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = recipes[i];
              return Card(
                child: ListTile(
                  leading: r.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(r.imageUrl!, width: 56, height: 56, fit: BoxFit.cover),
                        )
                      : const SizedBox(width: 56, height: 56, child: Icon(Icons.image_not_supported)),
                  title: Text(r.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          if (r.authorId != null) {
                            final authorAsync = ref.watch(authorProfileProvider(r.authorId!));
                            return authorAsync.when(
                              data: (authorInfo) {
                                final authorName = _getAuthorDisplayName(r, authorInfo);
                                return Text('By $authorName', style: TextStyle(color: Colors.grey[600], fontSize: 12));
                              },
                              loading: () => Text('By Community', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              error: (error, __) => Text('By Community', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            );
                          }
                          return Text('By Community', style: TextStyle(color: Colors.grey[600], fontSize: 12));
                        },
                      ),
                      if (r.protein != null)
                        Chip(
                          label: Text(r.protein!.name.toUpperCase()),
                          backgroundColor: Colors.green.shade100,
                          labelStyle: TextStyle(color: Colors.green.shade700, fontSize: 10),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
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
