// lib/pages/stores/stores_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import '../../providers/home_inventory_providers.dart';
import '../../models/moduels.dart';
import '../../utils/text_formatter.dart';
import '../../widgets/ingredient_autocomplete.dart';
import '../utils/logger.dart';

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
        heroTag: 'add-store-fab',
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
          // Home Inventory Section
          _buildHomeInventorySection(),
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
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final primaryContainer = scheme.primaryContainer;
    final onPrimaryContainer = scheme.onPrimaryContainer;
    
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
                            backgroundColor: primaryContainer.withValues(alpha: 0.7),
                            child: Icon(
                              Icons.store,
                              color: onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(store['store_name'] as String),
                          subtitle: Text('Priority ${store['priority']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.visibility, color: primary),
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
            logDebug('Initialized local stores list: ${_stores.map((s) => '${s.name} (${s.priority})').join(', ')}');
          }
          
          return ReorderableListView.builder(
            itemCount: _stores.length,
            onReorder: (oldIndex, newIndex) async {
              logDebug('Reordering: moving from index $oldIndex to $newIndex');
              
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _stores.removeAt(oldIndex);
                _stores.insert(newIndex, item);
              });
              
              // Log the new order
              logDebug('New store order:');
              for (int i = 0; i < _stores.length; i++) {
                logDebug('  ${i + 1}. ${_stores[i].name} (ID: ${_stores[i].id})');
              }
              
              // Update priorities in database based on new order
              final storeIds = _stores.map((store) => store.id).toList();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(reorderStoresProvider(storeIds).future);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Store order updated!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (error) {
                logDebug('Error updating store order: $error');
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to update store order: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
                // Revert the local state on error
                setState(() {
                  _stores = List.from(stores);
                });
              }
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

  Widget _buildHomeInventorySection() {
    final homeInventoryAsync = ref.watch(homeInventoryStreamProvider);
    final scheme = Theme.of(context).colorScheme;
    final homeColor = scheme.secondary;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(Icons.home, color: homeColor, size: 20),
        title: const Text('Home Inventory', style: TextStyle(fontSize: 16)),
        subtitle: homeInventoryAsync.when(
          data: (items) => Text('${items.length} items', style: const TextStyle(fontSize: 12)),
          loading: () => const Text('Loading...', style: TextStyle(fontSize: 12)),
          error: (_, __) => const Text('Error', style: TextStyle(fontSize: 12)),
        ),
        initiallyExpanded: false,
        children: [
          _HomeInventoryContent(),
        ],
      ),
    );
  }
}

class _DraggableStoreTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final highlightContainer = scheme.primaryContainer;
    final highlightText = scheme.onPrimaryContainer;
    final itemsAsync = ref.watch(storeItemsProvider(store.id));
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.drag_handle, color: Colors.grey),
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        title: Row(
          children: [
            Expanded(child: Text(store.name)),
            if (highlightedIngredient != null && isExpanded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: highlightContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Search: $highlightedIngredient',
                  style: TextStyle(
                    fontSize: 12,
                    color: highlightText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: itemsAsync.when(
          data: (items) => Text('${items.length} items', style: const TextStyle(fontSize: 12)),
          loading: () => const Text('Loading...', style: TextStyle(fontSize: 12)),
          error: (_, __) => const Text('Error', style: TextStyle(fontSize: 12)),
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
    logDebug('_StoreItems build method called for store: ${widget.storeId}');
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
                return _DeletableStoreItemChip(
                  storeItem: it,
                  searchTerm: widget.highlightedIngredient,
                  onDeleted: () {
                    // Invalidate the store items provider to refresh the list
                    ref.invalidate(storeItemsProvider(widget.storeId));
                  },
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
    logDebug('_AddItemButton build method called for store: ${widget.storeId}');
    return FilledButton(
      onPressed: _saving
          ? null
          : () async {
              final rawName = widget.ctrl.text.trim();
              final name = TextFormatter.toTitleCase(rawName);
              logDebug('Add button pressed for ingredient: "$rawName" -> "$name"');
              if (name.isEmpty) {
                logDebug('Ingredient name is empty, returning');
                return;
              }
              setState(() => _saving = true);
              final messenger = ScaffoldMessenger.of(context);
              logDebug('Calling addStoreItemProvider...');
              try {
                // Invalidate the provider first to ensure fresh execution
                ref.invalidate(addStoreItemProvider((storeId: widget.storeId, ingredientName: name)));
                await ref.read(addStoreItemProvider((storeId: widget.storeId, ingredientName: name)).future);
                logDebug('Successfully called addStoreItemProvider');
                // Invalidate the store items provider to refresh the list
                ref.invalidate(storeItemsProvider(widget.storeId));
                widget.ctrl.clear();
                logDebug('Cleared text field');
              } catch (e) {
                logDebug('Error adding ingredient: $e');
                if (!mounted) return;
                messenger.showSnackBar(
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
    final scheme = Theme.of(context).colorScheme;
    
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
                color: scheme.primaryContainer.withValues(alpha: 0.25),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: scheme.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Priority Assignment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      storesAsync.when(
                        data: (stores) => Text(
                          'This store will be added at position ${stores.length + 1} (Priority ${stores.length + 1}).\n\nYou can reorder stores by dragging them up or down in the list.',
                          style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer.withValues(alpha: 0.8)),
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
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
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
                    if (mounted) navigator.pop();
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
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

class _DeletableStoreItemChip extends ConsumerStatefulWidget {
  const _DeletableStoreItemChip({
    required this.storeItem,
    this.searchTerm,
    required this.onDeleted,
  });

  final StoreItem storeItem;
  final String? searchTerm;
  final VoidCallback onDeleted;

  @override
  ConsumerState<_DeletableStoreItemChip> createState() => _DeletableStoreItemChipState();
}

class _DeletableStoreItemChipState extends ConsumerState<_DeletableStoreItemChip> {
  bool _isDeleting = false;

  Future<void> _deleteItem() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(deleteStoreItemProvider(widget.storeItem.id).future);
      widget.onDeleted();
      
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Removed "${widget.storeItem.ingredientName}" from store'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to remove ingredient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this ingredient should be highlighted based on search term
    final shouldHighlight = widget.searchTerm != null && 
        widget.storeItem.ingredientName.toLowerCase().contains(widget.searchTerm!.toLowerCase());
    
    // For Chinese search terms, we need to check the database
    final isChineseSearch = widget.searchTerm != null && 
        RegExp(r'[\u4e00-\u9fff]').hasMatch(widget.searchTerm!);
    
    return Dismissible(
      key: Key(widget.storeItem.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.red.shade600,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Ingredient'),
            content: Text('Remove "${widget.storeItem.ingredientName}" from this store?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) {
        _deleteItem();
      },
      child: InkWell(
        onTap: null, // Disable tap on the entire chip
        child: isChineseSearch
            ? _BilingualHighlightChip(
                storeItem: widget.storeItem,
                searchTerm: widget.searchTerm!,
                isDeleting: _isDeleting,
                onDelete: _deleteItem,
              )
            : Chip(
                deleteIcon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                onDeleted: _deleteItem,
                label: Text(widget.storeItem.ingredientName),
                backgroundColor: shouldHighlight ? Colors.yellow.shade200 : null,
                side: shouldHighlight ? BorderSide(color: Colors.orange.shade400, width: 2) : null,
              ),
      ),
    );
  }
}

class _BilingualHighlightChip extends ConsumerWidget {
  const _BilingualHighlightChip({
    required this.storeItem,
    required this.searchTerm,
    required this.isDeleting,
    required this.onDelete,
  });

  final StoreItem storeItem;
  final String searchTerm;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(ingredientMatchesSearchProvider((
      ingredientName: storeItem.ingredientName,
      searchTerm: searchTerm,
    )));

    return matchAsync.when(
      data: (shouldHighlight) => Chip(
        deleteIcon: isDeleting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.close,
                size: 14,
                color: Colors.grey.shade600,
              ),
        onDeleted: onDelete,
        label: Text(storeItem.ingredientName),
        backgroundColor: shouldHighlight ? Colors.yellow.shade200 : null,
        side: shouldHighlight ? BorderSide(color: Colors.orange.shade400, width: 2) : null,
      ),
      loading: () => Chip(
        deleteIcon: isDeleting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.close,
                size: 14,
                color: Colors.grey.shade600,
              ),
        onDeleted: onDelete,
        label: Text(storeItem.ingredientName),
      ),
      error: (_, __) => Chip(
        deleteIcon: isDeleting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.close,
                size: 14,
                color: Colors.grey.shade600,
              ),
        onDeleted: onDelete,
        label: Text(storeItem.ingredientName),
      ),
    );
  }
}

class _HomeInventoryContent extends ConsumerStatefulWidget {
  const _HomeInventoryContent();

  @override
  ConsumerState<_HomeInventoryContent> createState() => _HomeInventoryContentState();
}

class _HomeInventoryContentState extends ConsumerState<_HomeInventoryContent> {
  final _ingredientCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();

  @override
  void dispose() {
    _ingredientCtrl.dispose();
    _unitCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeInventoryAsync = ref.watch(homeInventoryStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add new item section - more compact
          Row(
            children: [
              Expanded(
                flex: 2,
                child: IngredientAutocomplete(
                  controller: _ingredientCtrl,
                  hintText: 'Ingredient',
                  onChanged: (value) {
                    // Handle ingredient selection
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _quantityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _unitCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _AddHomeInventoryButton(
                ingredientCtrl: _ingredientCtrl,
                unitCtrl: _unitCtrl,
                quantityCtrl: _quantityCtrl,
                onAdded: () {
                  _ingredientCtrl.clear();
                  _unitCtrl.clear();
                  _quantityCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Current home inventory items
          const Text('Items at Home:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          homeInventoryAsync.when(
            data: (items) => ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: items.map((item) {
                    return _DeletableHomeInventoryChip(
                      item: item,
                      onDeleted: () {
                        ref.invalidate(homeInventoryStreamProvider);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(4.0),
              child: CircularProgressIndicator(),
            ),
            error: (e, st) => Text('Error: $e', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _AddHomeInventoryButton extends ConsumerStatefulWidget {
  const _AddHomeInventoryButton({
    required this.ingredientCtrl,
    required this.unitCtrl,
    required this.quantityCtrl,
    required this.onAdded,
  });

  final TextEditingController ingredientCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController quantityCtrl;
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddHomeInventoryButton> createState() => _AddHomeInventoryButtonState();
}

class _AddHomeInventoryButtonState extends ConsumerState<_AddHomeInventoryButton> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: _saving ? null : _addItem,
        child: _saving 
            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Add', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<void> _addItem() async {
    final ingredientName = widget.ingredientCtrl.text.trim();
    if (ingredientName.isEmpty) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final quantity = double.tryParse(widget.quantityCtrl.text.trim());
      final unit = widget.unitCtrl.text.trim().isEmpty ? null : widget.unitCtrl.text.trim();

      await ref.read(addHomeInventoryItemProvider((
        ingredientName: ingredientName,
        unit: unit,
        quantity: quantity,
      )).future);

      ref.invalidate(homeInventoryStreamProvider);
      widget.onAdded();

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Added "$ingredientName" to home inventory'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DeletableHomeInventoryChip extends ConsumerStatefulWidget {
  const _DeletableHomeInventoryChip({
    required this.item,
    required this.onDeleted,
  });

  final HomeInventoryItem item;
  final VoidCallback onDeleted;

  @override
  ConsumerState<_DeletableHomeInventoryChip> createState() => _DeletableHomeInventoryChipState();
}

class _DeletableHomeInventoryChipState extends ConsumerState<_DeletableHomeInventoryChip> {
  bool _isDeleting = false;

  Future<void> _deleteItem() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(deleteHomeInventoryItemProvider(widget.item.id).future);
      widget.onDeleted();

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Removed "${widget.item.ingredientName}" from home inventory'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantityText = widget.item.quantity != null ? '${widget.item.quantity}' : '';
    final unitText = widget.item.unit != null ? ' ${widget.item.unit}' : '';
    final displayText = quantityText.isNotEmpty 
        ? '${widget.item.ingredientName} ($quantityText$unitText)'
        : widget.item.ingredientName;
    final scheme = Theme.of(context).colorScheme;
    final homeColor = scheme.secondary;

    return Chip(
      deleteIcon: _isDeleting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.close,
              size: 14,
              color: Colors.grey.shade600,
            ),
      onDeleted: _deleteItem,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home, size: 16, color: homeColor),
          const SizedBox(width: 6),
          Text(displayText),
        ],
      ),
    );
  }
}
