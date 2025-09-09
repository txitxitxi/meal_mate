import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recipe_providers.dart';
import '../../models/models.dart';

class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
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
                leading: r.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(r.photoUrl!, width: 56, height: 56, fit: BoxFit.cover),
                      )
                    : const SizedBox(width: 56, height: 56, child: Icon(Icons.image_not_supported)),
                title: Text(r.title),
                subtitle: Text(r.id),
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
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final args = (
              title: _titleCtrl.text.trim(),
              photoUrl: _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim(),
              ingredients: _ings,
            );
            await ref.read(addRecipeProvider(args).future);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
