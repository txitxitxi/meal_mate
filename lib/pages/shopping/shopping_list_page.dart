import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/weekly_shopping_providers.dart';
import '../../models/models.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: itemsAsync.when(
        data: (items) {
          final grouped = _groupByStore(items);
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, i) {
              final entry = grouped.entries.elementAt(i);
              final storeName = entry.key ?? 'Unassigned';
              final list = entry.value;
              return Card(
                child: ExpansionTile(
                  title: Text(storeName),
                  initiallyExpanded: i == 0,
                  children: list.map((item) => _ShoppingItemTile(item: item)).toList(),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: grouped.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

Map<String?, List<ShoppingListItem>> _groupByStore(List<ShoppingListItem> items) {
  final map = <String?, List<ShoppingListItem>>{};
  for (final it in items) {
    map.putIfAbsent(it.storeName ?? 'Unassigned', () => []).add(it);
  }
  return map;
}

class _ShoppingItemTile extends ConsumerWidget {
  const _ShoppingItemTile({required this.item});
  final ShoppingListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: item.purchased,
      onChanged: (_) => ref.read(togglePurchasedProvider(item.id).future),
      title: Text(item.ingredientName),
      subtitle: Row(
        children: [
          if (item.qty != null) Text('${item.qty} '),
          if (item.unit != null) Text(item.unit!),
        ],
      ),
    );
  }
}
