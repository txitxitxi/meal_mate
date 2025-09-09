// lib/pages/stores/stores_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_providers.dart';
import '../../models/models.dart';

class StoresPage extends ConsumerWidget {
  const StoresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
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
                  if (s.isDefault)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Chip(label: Text('Default')),
                    ),
                ],
              ),
              children: const [
                SizedBox(height: 8),
              ]..insert(1, _StoreItems(storeId: s.id)), // keep children order tidy
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
              FilledButton(
                onPressed: () async {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  await ref
                      .read(addStoreItemProvider((storeId: storeId, ingredientName: name)).future);
                  ctrl.clear();
                },
                child: const Text('Add'),
              )
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
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final priority = int.tryParse(_priorityCtrl.text.trim());
            await ref.read(addStoreProvider((
              name: _nameCtrl.text.trim(),
              isDefault: _isDefault,
              priority: priority,
            )).future);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
