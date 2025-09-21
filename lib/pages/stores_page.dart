// lib/pages/stores/stores_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import '../../models/moduels.dart';
import '../../utils/text_formatter.dart';
import '../../widgets/ingredient_autocomplete.dart';

class StoresPage extends ConsumerStatefulWidget {
  const StoresPage({super.key});

  @override
  ConsumerState<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends ConsumerState<StoresPage> {
  List<Store> _stores = [];
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String? _expandedStoreId;
  String? _highlightedIngredient;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToStoreAndHighlight(BuildContext context, String storeId, String ingredientName) {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _expandedStoreId = storeId;
      _highlightedIngredient = ingredientName;
    });
    
    // Show a snackbar to indicate what happened
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expanded store to show "$ingredientName"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesStreamProvider);
    
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (_) => const _AddStoreDialog()),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Store'),
      ),
      body: Column(
        children: [
          // Search bar with refresh button
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ingredients (e.g., "beef", "broccoli")',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _isSearching = false);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        // Force refresh stores
                        ref.read(storesRefreshProvider.notifier).state++;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Refreshing stores...')),
                        );
                      },
                      tooltip: 'Refresh Stores',
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _isSearching = value.isNotEmpty);
              },
            ),
          ),
          // Content based on search state
          Expanded(
            child: _isSearching 
                ? _buildSearchResults()
                : _buildStoreList(storesAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isEmpty) {
      return const Center(child: Text('Enter an ingredient name to search'));
    }

    final searchAsync = ref.watch(searchStoresByIngredientProvider(searchQuery));
    
    return searchAsync.when(
      data: (stores) => stores.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No stores found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No stores sell "$searchQuery"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Stores that sell "$searchQuery"',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.store,
                              color: Colors.blue.shade800,
                              size: 20,
                            ),
                          ),
                          title: Text(store['store_name'] as String),
                          subtitle: Text('Priority ${store['priority']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () => _navigateToStoreAndHighlight(
                              context, 
                              store['store_id'] as String,
                              _searchController.text.trim(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Error searching: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(searchStoresByIngredientProvider(searchQuery)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreList(AsyncValue<List<Store>> storesAsync) {
    return storesAsync.when(
        data: (stores) {
          // Update local stores list when data changes
          if (_stores.isEmpty || _stores.length != stores.length) {
            _stores = List.from(stores);
            print('Initialized local stores list: ${_stores.map((s) => '${s.name} (${s.priority})').join(', ')}');
          }
          
          return ReorderableListView.builder(
            itemCount: _stores.length,
            onReorder: (oldIndex, newIndex) {
              print('Reordering: moving from index $oldIndex to $newIndex');
              
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _stores.removeAt(oldIndex);
                _stores.insert(newIndex, item);
              });
              
              // Log the new order
              print('New store order:');
              for (int i = 0; i < _stores.length; i++) {
                print('  ${i + 1}. ${_stores[i].name} (ID: ${_stores[i].id})');
              }
              
              // Update priorities in database based on new order
              final storeIds = _stores.map((store) => store.id).toList();
              ref.read(reorderStoresProvider(storeIds).future).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Store order updated!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }).catchError((error) {
                print('Error updating store order: $error');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update store order: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
                // Revert the local state on error
                setState(() {
                  _stores = List.from(stores);
                });
              });
            },
            itemBuilder: (context, i) {
              final s = _stores[i];
            return _DraggableStoreTile(
              key: ValueKey(s.id),
              store: s,
              index: i,
              isExpanded: _expandedStoreId == s.id,
              highlightedIngredient: _highlightedIngredient,
              onExpansionChanged: (isExpanded) {
                setState(() {
                  if (isExpanded) {
                    _expandedStoreId = s.id;
                  } else {
                    _expandedStoreId = null;
                    _highlightedIngredient = null;
                  }
                });
              },
            );
            },
          );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _DraggableStoreTile extends StatelessWidget {
  const _DraggableStoreTile({
    super.key,
    required this.store,
    required this.index,
    required this.isExpanded,
    this.highlightedIngredient,
    this.onExpansionChanged,
  });
  
  final Store store;
  final int index;
  final bool isExpanded;
  final String? highlightedIngredient;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.drag_handle, color: Colors.grey),
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        title: Row(
          children: [
            // Show position number
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(store.name)),
            if (highlightedIngredient != null && isExpanded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Search: $highlightedIngredient',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        children: [
          const SizedBox(height: 8),
          _StoreItems(
            storeId: store.id,
            highlightedIngredient: highlightedIngredient,
          ),
        ],
      ),
    );
  }
}

class _StoreItems extends ConsumerStatefulWidget {
  const _StoreItems({
    required this.storeId,
    this.highlightedIngredient,
  });
  final String storeId;
  final String? highlightedIngredient;

  @override
  ConsumerState<_StoreItems> createState() => _StoreItemsState();
}

class _StoreItemsState extends ConsumerState<_StoreItems> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('_StoreItems build method called for store: ${widget.storeId}');
    final itemsAsync = ref.watch(storeItemsProvider(widget.storeId));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: IngredientAutocomplete(
                  controller: _ctrl,
                  hintText: 'Add ingredient this store sells (e.g., Broccoli)',
                  onChanged: (value) {
                    // The autocomplete widget handles formatting
                  },
                ),
              ),
              const SizedBox(width: 8),
              _AddItemButton(storeId: widget.storeId, ctrl: _ctrl),
            ],
          ),
          const SizedBox(height: 8),
          itemsAsync.when(
            data: (items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((it) {
                final isHighlighted = widget.highlightedIngredient != null && 
                    it.ingredientName.toLowerCase().contains(widget.highlightedIngredient!.toLowerCase());
                
                return Chip(
                  label: Text(it.ingredientName),
                  backgroundColor: isHighlighted ? Colors.yellow.shade200 : null,
                  side: isHighlighted ? BorderSide(color: Colors.orange.shade400, width: 2) : null,
                );
              }).toList(),
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
    print('_AddItemButton build method called for store: ${widget.storeId}');
    return FilledButton(
      onPressed: _saving
          ? null
          : () async {
              final rawName = widget.ctrl.text.trim();
              final name = TextFormatter.toTitleCase(rawName);
              print('Add button pressed for ingredient: "$rawName" -> "$name"');
              if (name.isEmpty) {
                print('Ingredient name is empty, returning');
                return;
              }
              setState(() => _saving = true);
              print('Calling addStoreItemProvider...');
              try {
                await ref.read(addStoreItemProvider((storeId: widget.storeId, ingredientName: name)).future);
                print('Successfully called addStoreItemProvider');
                // Invalidate the store items provider to refresh the list
                ref.invalidate(storeItemsProvider(widget.storeId));
                widget.ctrl.clear();
                print('Cleared text field');
              } catch (e) {
                print('Error adding ingredient: $e');
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
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;


  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesStreamProvider);
    
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
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Priority Assignment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      storesAsync.when(
                        data: (stores) => Text(
                          'This store will be added at position ${stores.length + 1} (Priority ${stores.length + 1}).\n\nYou can reorder stores by dragging them up or down in the list.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                        ),
                        loading: () => const Text('Calculating position...'),
                        error: (_, __) => const Text('Unable to calculate position'),
                      ),
                    ],
                  ),
                ),
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
                  
                  // Get the current store count for auto-assigned priority
                  final stores = await ref.read(storesStreamProvider.future);
                  final autoPriority = stores.length + 1;
                  
                  try {
                    await ref.read(addStoreProvider((
                      name: _nameCtrl.text.trim(),
                      priority: autoPriority,
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
