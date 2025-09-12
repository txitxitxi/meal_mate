// lib/pages/stores/stores_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import '../../models/moduels.dart';

class StoresPage extends ConsumerWidget {
  const StoresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesStreamProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (_) => const _AddStoreDialog()),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Store'),
      ),
      body: storesAsync.when(
        data: (stores) => ListView.builder(
          itemCount: stores.length,
          itemBuilder: (context, i) {
            final s = stores[i];
            return ExpansionTile(
              title: Row(
                children: [
                  Text(s.name),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('Priority ${s.priority}'),
                    backgroundColor: s.priority <= 2 ? Colors.green.shade100 : 
                                   s.priority <= 5 ? Colors.orange.shade100 : 
                                   Colors.red.shade100,
                  ),
                  if (s.isDefault)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Chip(label: Text('Default')),
                    ),
                ],
              ),
              children: [
                const SizedBox(height: 8),
                _StoreItems(storeId: s.id),
              ],
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StoreItems extends ConsumerWidget {
  const _StoreItems({required this.storeId});
  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(storeItemsProvider(storeId));
    final ctrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Add ingredient this store sells (e.g., Broccoli)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _AddItemButton(storeId: storeId, ctrl: ctrl),
            ],
          ),
          const SizedBox(height: 8),
          itemsAsync.when(
            data: (items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((it) => Chip(label: Text(it.ingredientName))).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
            error: (e, st) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _AddItemButton extends ConsumerStatefulWidget {
  const _AddItemButton({required this.storeId, required this.ctrl});
  final String storeId;
  final TextEditingController ctrl;
  @override
  ConsumerState<_AddItemButton> createState() => _AddItemButtonState();
}

class _AddItemButtonState extends ConsumerState<_AddItemButton> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _saving
          ? null
          : () async {
              final name = widget.ctrl.text.trim();
              if (name.isEmpty) return;
              setState(() => _saving = true);
              try {
                await ref.read(addStoreItemProvider((storeId: widget.storeId, ingredientName: name)).future);
                // Invalidate the store items provider to refresh the list
                ref.invalidate(storeItemsProvider(widget.storeId));
                widget.ctrl.clear();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add item: $e')),
                );
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
      child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) : const Text('Add'),
    );
  }
}

class _AddStoreDialog extends ConsumerStatefulWidget {
  const _AddStoreDialog();
  @override
  ConsumerState<_AddStoreDialog> createState() => _AddStoreDialogState();
}

class _AddStoreDialogState extends ConsumerState<_AddStoreDialog> {
  final _nameCtrl = TextEditingController();
  bool _isDefault = false;
  final _priorityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Store'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Store Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priorityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Priority (lower = earlier stop)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: const Text('Default store'),
              ),
            ],
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
                  final priority = int.tryParse(_priorityCtrl.text.trim());
                  try {
                    await ref.read(addStoreProvider((
                      name: _nameCtrl.text.trim(),
                      isDefault: _isDefault,
                      priority: priority,
                    )).future);
                    // Invalidate the stores provider to refresh the list
                    ref.invalidate(storesStreamProvider);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save store: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
              : const Text('Save'),
        ),
      ],
    );
  }
}
