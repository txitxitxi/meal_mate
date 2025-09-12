import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/weekly_shopping_providers.dart';
import '../../models/moduels.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListProvider);
    final generateShoppingListAsync = ref.watch(generateShoppingListProvider);
    
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            await ref.read(generateShoppingListProvider.future);
            // Invalidate the shopping list provider to refresh the list
            ref.invalidate(shoppingListProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shopping list generated successfully!')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to generate shopping list: $e')),
              );
            }
          }
        },
        label: const Text('Generate List'),
        icon: const Icon(Icons.shopping_cart),
      ),
      body: Column(
        children: [
          if (generateShoppingListAsync.isLoading) 
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: itemsAsync.when(
        data: (items) {
          print('Shopping list items count: ${items.length}');
          print('Shopping list items: $items');
          final grouped = _groupByStore(items);
          print('Grouped by store: $grouped');
          
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No items in shopping list', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Generate a weekly plan first, then create a shopping list', 
                       style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          
          // Sort stores: named stores first, then "No Store" at the end
          final sortedEntries = grouped.entries.toList()
            ..sort((a, b) {
              if (a.key == 'No Store') return 1;
              if (b.key == 'No Store') return -1;
              return a.key.compareTo(b.key);
            });
          
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, i) {
              final entry = sortedEntries[i];
              final storeName = entry.key;
              final list = entry.value;
              final isNoStore = storeName == 'No Store';
              
              return Card(
                elevation: isNoStore ? 2 : 1,
                color: isNoStore ? Colors.orange.shade50 : null,
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Icon(
                        isNoStore ? Icons.warning_amber : Icons.store,
                        color: isNoStore ? Colors.orange : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        storeName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isNoStore ? Colors.orange.shade700 : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${list.length} items'),
                        backgroundColor: isNoStore ? Colors.orange.shade100 : Colors.blue.shade100,
                        labelStyle: TextStyle(
                          color: isNoStore ? Colors.orange.shade700 : Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  initiallyExpanded: i == 0,
                  children: list.map((item) => _ShoppingItemTile(item: item)).toList(),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: sortedEntries.length,
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
}

Map<String, List<ShoppingListItem>> _groupByStore(List<ShoppingListItem> items) {
  final map = <String, List<ShoppingListItem>>{};
  for (final it in items) {
    final storeName = it.storeName ?? 'No Store';
    map.putIfAbsent(storeName, () => []).add(it);
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
