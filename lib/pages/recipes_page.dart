import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/auth_providers.dart';
import '../../models/moduels.dart' hide Recipe; // Hide Recipe from moduels.dart to avoid conflict
import '../../models/recipe.dart';
import '../../utils/text_formatter.dart';
import '../../widgets/ingredient_autocomplete.dart';
import '../utils/logger.dart';

class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  @override
  void initState() {
    super.initState();
    // Refresh data when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(myRecipesStreamProvider);
        ref.invalidate(userOwnRecipesStreamProvider);
        ref.invalidate(userSavedRecipesStreamProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(myRecipesStreamProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-recipe-fab',
        onPressed: () => showDialog(context: context, builder: (_) => const _AddRecipeDialog()),
        icon: const Icon(Icons.restaurant),
        label: const Text('Add Recipe'),
      ),
      body: recipesAsync.when(
        data: (recipes) => RefreshIndicator(
          onRefresh: () async {
            // Refresh the recipes
            ref.invalidate(myRecipesStreamProvider);
            ref.invalidate(userOwnRecipesStreamProvider);
            ref.invalidate(userSavedRecipesStreamProvider);
            // Wait a bit for the refresh to complete
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = recipes[i];
                      return Consumer(
                        builder: (context, ref, child) {
                          // Check if recipe is owned (all recipes in "My Recipe" are either owned or saved)
                          final currentUser = ref.watch(currentUserProvider);
                          final isOwnRecipe = currentUser?.id == r.authorId;
                          
                          // Use slightly darker color if owned or saved (all recipes here are one or the other)
                          final cardColor = Theme.of(context).cardColor.withValues(alpha: 0.85);
                          
                          return Card(
                            color: cardColor,
                            child: ListTile(
                leading: r.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(r.imageUrl!, width: 56, height: 56, fit: BoxFit.cover),
                      )
                    : const SizedBox(width: 56, height: 56, child: Icon(Icons.image_not_supported)),
                title: Row(
                  children: [
                    Expanded(child: Text(r.title)),
                    Consumer(
                      builder: (context, ref, child) {
                        final currentUser = ref.watch(currentUserProvider);
                        final isOwnRecipe = currentUser?.id == r.authorId;
                        if (isOwnRecipe) {
                          return const SizedBox.shrink(); // No indicator for own recipes
                        } else {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'SAVED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Public/Private toggle (only for own recipes)
                    Consumer(
                      builder: (context, ref, child) {
                        final currentUser = ref.watch(currentUserProvider);
                        final isOwnRecipe = currentUser?.id == r.authorId;
                        
                        if (!isOwnRecipe) {
                          return const SizedBox.shrink(); // No toggle for saved recipes
                        }
                        
                        final messenger = ScaffoldMessenger.of(context);
                        return IconButton(
                          onPressed: () async {
                            try {
                              final newVisibility = r.visibility == RecipeVisibility.public 
                                  ? RecipeVisibility.private 
                                  : RecipeVisibility.public;
                              
                              await ref.read(updateRecipeVisibilityProvider((
                                recipeId: r.id,
                                visibility: newVisibility,
                              )).future);
                              
                              // Invalidate the recipes provider to refresh the list
                              ref.invalidate(myRecipesStreamProvider);
                              ref.invalidate(userOwnRecipesStreamProvider);
                              ref.invalidate(publicRecipesStreamProvider);
                              
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Recipe is now ${newVisibility.name}'),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed to update recipe visibility: $e')),
                              );
                            }
                          },
                          icon: Icon(
                            r.visibility == RecipeVisibility.public 
                                ? Icons.public 
                                : Icons.lock,
                            color: r.visibility == RecipeVisibility.public 
                                ? scheme.secondary 
                                : scheme.primary,
                          ),
                          tooltip: r.visibility == RecipeVisibility.public 
                              ? 'Make Private' 
                              : 'Make Public',
                        );
                      },
                    ),
                    // More options menu (only for own recipes)
                    Consumer(
                      builder: (context, ref, child) {
                        final currentUser = ref.watch(currentUserProvider);
                        final isOwnRecipe = currentUser?.id == r.authorId;
                        
                        if (!isOwnRecipe) {
                          return const SizedBox.shrink(); // No menu for saved recipes
                        }
                        
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        return PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              showDialog(
                                context: context,
                                builder: (_) => _EditRecipeDialog(recipe: r),
                              );
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Recipe'),
                                  content: Text('Are you sure you want to delete "${r.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        navigator.pop();
                                        try {
                                          await ref.read(deleteRecipeProvider(r.id).future);
                                          // Invalidate the recipes provider to refresh the list
                                          ref.invalidate(myRecipesStreamProvider);
                                          ref.invalidate(userOwnRecipesStreamProvider);
                                          messenger.showSnackBar(
                                            const SnackBar(content: Text('Recipe deleted successfully')),
                                          );
                                        } catch (e) {
                                          messenger.showSnackBar(
                                            SnackBar(content: Text('Failed to delete recipe: $e')),
                                          );
                                        }
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        );
                      },
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
                            if (r.imageUrl != null) const SizedBox(height: 16),
                            if (r.protein != ProteinPreference.none) ...[
                              Row(
                                children: [
                                  const Text('Protein Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Chip(
                                    label: Text(r.protein.name.toUpperCase()),
                                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.7),
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
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
                            final currentUser = ref.watch(currentUserProvider);
                            final isOwnRecipe = currentUser?.id == r.authorId;
                            
                            // Don't show save/unsave for own recipes
                            if (isOwnRecipe) {
                              return const SizedBox.shrink();
                            }
                            
                            final isSavedAsync = ref.watch(isRecipeSavedProvider(r.id));
                            final messenger = ScaffoldMessenger.of(context);
                            return isSavedAsync.when(
                              data: (isSaved) => FilledButton.icon(
                                onPressed: () async {
                                  try {
                                    if (isSaved) {
                                      await ref.read(unsaveRecipeProvider(r.id).future);
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Recipe unsaved')),
                                      );
                                    } else {
                                      await ref.read(saveRecipeProvider(r.id).future);
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Recipe saved to your collection!')),
                                      );
                                    }
                                    // Wait a bit for the database operation to complete
                                    await Future.delayed(const Duration(milliseconds: 300));
                                    // Refresh all related providers BEFORE closing dialog
                                    ref.invalidate(isRecipeSavedProvider(r.id));
                                    ref.invalidate(userSavedRecipesStreamProvider);
                                    ref.invalidate(myRecipesStreamProvider);
                                    ref.invalidate(userOwnRecipesStreamProvider);
                                    // Close dialog after refreshing
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    messenger.showSnackBar(
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
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Recipe saved to your collection!')),
                                    );
                                    // Close dialog first
                                    Navigator.pop(context);
                                    // Wait a bit for the database operation to complete
                                    await Future.delayed(const Duration(milliseconds: 300));
                                    // Refresh all related providers
                                    ref.invalidate(isRecipeSavedProvider(r.id));
                                    ref.invalidate(userSavedRecipesStreamProvider);
                                    ref.invalidate(myRecipesStreamProvider);
                                    ref.invalidate(userOwnRecipesStreamProvider);
                                  } catch (e) {
                                    messenger.showSnackBar(
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
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AddRecipeDialog extends ConsumerStatefulWidget {
  const _AddRecipeDialog();
  @override
  ConsumerState<_AddRecipeDialog> createState() => _AddRecipeDialogState();
}

class _AddRecipeDialogState extends ConsumerState<_AddRecipeDialog> {
  final _titleCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<IngredientInput> _ings = [IngredientInput()];
  bool _saving = false;
  ProteinPreference _selectedProtein = ProteinPreference.none;
  
  void _addRow() => setState(() => _ings.add(IngredientInput()));

  String _formatTitleForSave(String title) {
    // Only format if the text doesn't contain Chinese characters
    if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(title)) {
      return TextFormatter.toTitleCase(title);
    }
    return title;
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Recipe'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _photoCtrl,
                  decoration: const InputDecoration(labelText: 'Photo URL (optional)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProteinPreference>(
                  value: _selectedProtein,
                  decoration: const InputDecoration(
                    labelText: 'Protein Type (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: ProteinPreference.values.map((pref) {
                    return DropdownMenuItem(
                      value: pref,
                      child: Text(pref == ProteinPreference.none 
                          ? 'None' 
                          : pref.name[0].toUpperCase() + pref.name.substring(1))
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProtein = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Ingredients'),
                const SizedBox(height: 8),
                ..._ings.asMap().entries.map((e) {
                  final i = e.key;
                  final ing = e.value;
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: IngredientAutocomplete(
                          controller: TextEditingController(text: ing.name),
                          labelText: 'Ingredient ${i + 1}',
                          onChanged: (v) => ing.name = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Qty'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => ing.qty = double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Unit'),
                          onChanged: (v) => ing.unit = v,
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Ingredient'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _saving = true);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final args = (
                    title: _formatTitleForSave(_titleCtrl.text.trim()),
                    description: null,
                    photoUrl: _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim(),
                    protein: _selectedProtein,
                    cuisine: null,
                    servings: 2,
                    prepTimeMin: null,
                    cookTimeMin: null,
                    visibility: RecipeVisibility.public,
                    ingredients: _ings,
                  );
                  try {
                    await ref.read(addRecipeProvider(args).future);
                    // Invalidate all recipe-related providers to refresh the list
                    ref.invalidate(myRecipesStreamProvider);
                    ref.invalidate(userOwnRecipesStreamProvider);
                    ref.invalidate(publicRecipesStreamProvider);
                    if (mounted) navigator.pop();
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to save recipe: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) : const Text('Save'),
        ),
      ],
    );
  }
}

class _EditRecipeDialog extends ConsumerStatefulWidget {
  const _EditRecipeDialog({required this.recipe});
  final Recipe recipe;

  @override
  ConsumerState<_EditRecipeDialog> createState() => _EditRecipeDialogState();
}

class _EditRecipeDialogState extends ConsumerState<_EditRecipeDialog> {
  final _titleCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<IngredientInput> _ings = [];
  bool _saving = false;
  late ProteinPreference _selectedProtein;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.recipe.title;
    _photoCtrl.text = widget.recipe.imageUrl ?? '';
    _selectedProtein = widget.recipe.protein;
    // Start with one empty ingredient as fallback
    _ings.add(IngredientInput());
  }

  void _addRow() => setState(() => _ings.add(IngredientInput()));
  void _removeRow(int index) => setState(() => _ings.removeAt(index));

  String _formatTitleForSave(String title) {
    // Only format if the text doesn't contain Chinese characters
    if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(title)) {
      return TextFormatter.toTitleCase(title);
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    // Load existing ingredients reactively
    final ingredientsAsync = ref.watch(recipeIngredientsProvider(widget.recipe.id));
    ingredientsAsync.when(
      data: (ingredients) {
        logDebug('Edit Recipe: Loading ingredients for recipe ${widget.recipe.id}, found ${ingredients.length} ingredients');
        if (ingredients.isNotEmpty && _ings.length == 1 && _ings.first.name.isEmpty) {
          // Only update if we still have the empty fallback ingredient
          logDebug('Edit Recipe: Updating ingredients list with ${ingredients.length} items');
          setState(() {
            _ings.clear();
            for (final ingredient in ingredients) {
              final ingredientData = ingredient['ingredients'] as Map<String, dynamic>;
              _ings.add(IngredientInput(
                name: ingredientData['name'] as String,
                qty: (ingredient['quantity'] as num?)?.toDouble(),
                unit: ingredient['unit'] as String?,
              ));
            }
          });
        }
      },
      loading: () {
        logDebug('Edit Recipe: Loading ingredients...');
        // Keep the empty ingredient while loading
      },
      error: (error, stack) {
        logDebug('Edit Recipe: Error loading ingredients: $error');
        // Keep the empty ingredient on error
      },
    );

    return AlertDialog(
      title: const Text('Edit Recipe'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _photoCtrl,
                  decoration: const InputDecoration(labelText: 'Photo URL (optional)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProteinPreference>(
                  value: _selectedProtein,
                  decoration: const InputDecoration(
                    labelText: 'Protein Type (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: ProteinPreference.values.map((pref) {
                    return DropdownMenuItem(
                      value: pref,
                      child: Text(pref == ProteinPreference.none 
                          ? 'None' 
                          : pref.name[0].toUpperCase() + pref.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProtein = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Ingredients'),
                const SizedBox(height: 8),
                ..._ings.asMap().entries.map((e) {
                  final i = e.key;
                  final ing = e.value;
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: IngredientAutocomplete(
                          controller: TextEditingController(text: ing.name),
                          labelText: 'Ingredient ${i + 1}',
                          onChanged: (v) => ing.name = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: TextEditingController(text: ing.qty?.toString() ?? ''),
                          decoration: const InputDecoration(labelText: 'Qty'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => ing.qty = double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: TextEditingController(text: ing.unit ?? ''),
                          decoration: const InputDecoration(labelText: 'Unit'),
                          onChanged: (v) => ing.unit = v,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _ings.length > 1 ? () => _removeRow(i) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Remove ingredient',
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Ingredient'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _saving = true);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final args = (
                      recipeId: widget.recipe.id,
                      title: _formatTitleForSave(_titleCtrl.text.trim()),
                      photoUrl: _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim(),
                      protein: _selectedProtein,
                      ingredients: _ings,
                    );
                    await ref.read(updateRecipeProvider(args).future);
                    // Invalidate the recipes provider to refresh the list
                    ref.invalidate(myRecipesStreamProvider);
                    ref.invalidate(userOwnRecipesStreamProvider);
                    ref.invalidate(recipeIngredientsProvider(widget.recipe.id));
                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Recipe updated successfully')),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update recipe: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) : const Text('Save'),
        ),
      ],
    );
  }
}
