import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recipe_providers.dart';
import '../../models/moduels.dart';

class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesStreamProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (_) => const _AddRecipeDialog()),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: recipesAsync.when(
        data: (recipes) => ListView.separated(
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
                trailing: PopupMenuButton<String>(
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
                                Navigator.pop(context);
                                try {
                                  await ref.read(deleteRecipeProvider(r.id).future);
                                  // Invalidate the recipes provider to refresh the list
                                  ref.invalidate(recipesStreamProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Recipe deleted successfully')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                      ],
                    ),
                  );
                },
              ),
            );
          },
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
  String _selectedProtein = 'none';
  
  final List<String> _availableProteins = [
    'none',
    'chicken',
    'beef', 
    'pork',
    'fish',
    'seafood',
    'vegetarian',
    'vegan'
  ];

  void _addRow() => setState(() => _ings.add(IngredientInput()));

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
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _photoCtrl,
                  decoration: const InputDecoration(labelText: 'Photo URL (optional)'),
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
                        child: TextFormField(
                          decoration: InputDecoration(labelText: 'Ingredient ${i + 1}'),
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
                  final args = (
                    title: _titleCtrl.text.trim(),
                    photoUrl: _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim(),
                    protein: _selectedProtein,
                    ingredients: _ings,
                  );
                  try {
                    await ref.read(addRecipeProvider(args).future);
                    // Invalidate the recipes provider to refresh the list
                    ref.invalidate(recipesStreamProvider);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.recipe.title;
    _photoCtrl.text = widget.recipe.imageUrl ?? '';
    // Start with one empty ingredient as fallback
    _ings.add(IngredientInput());
  }

  void _addRow() => setState(() => _ings.add(IngredientInput()));
  void _removeRow(int index) => setState(() => _ings.removeAt(index));

  @override
  Widget build(BuildContext context) {
    // Load existing ingredients reactively
    final ingredientsAsync = ref.watch(recipeIngredientsProvider(widget.recipe.id));
    ingredientsAsync.when(
      data: (ingredients) {
        print('Edit Recipe: Loading ingredients for recipe ${widget.recipe.id}, found ${ingredients.length} ingredients');
        if (ingredients.isNotEmpty && _ings.length == 1 && _ings.first.name.isEmpty) {
          // Only update if we still have the empty fallback ingredient
          print('Edit Recipe: Updating ingredients list with ${ingredients.length} items');
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
        print('Edit Recipe: Loading ingredients...');
        // Keep the empty ingredient while loading
      },
      error: (error, stack) {
        print('Edit Recipe: Error loading ingredients: $error');
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
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _photoCtrl,
                  decoration: const InputDecoration(labelText: 'Photo URL (optional)'),
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
                        child: TextFormField(
                          controller: TextEditingController(text: ing.name),
                          decoration: InputDecoration(labelText: 'Ingredient ${i + 1}'),
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
                  try {
                    final args = (
                      recipeId: widget.recipe.id,
                      title: _titleCtrl.text.trim(),
                      photoUrl: _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim(),
                      ingredients: _ings,
                    );
                    await ref.read(updateRecipeProvider(args).future);
                    // Invalidate the recipes provider to refresh the list
                    ref.invalidate(recipesStreamProvider);
                    ref.invalidate(recipeIngredientsProvider(widget.recipe.id));
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Recipe updated successfully')),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
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
