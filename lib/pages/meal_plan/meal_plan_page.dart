// lib/pages/meal_plan/meal_plan_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/meal_plan_providers.dart';
import '../../providers/home_inventory_providers.dart';
import '../../models/moduels.dart';
import '../../utils/protein_preferences.dart';

class MealPlanPage extends ConsumerStatefulWidget {
  const MealPlanPage({super.key});

  @override
  ConsumerState<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends ConsumerState<MealPlanPage> with TickerProviderStateMixin {
  final List<String> _selectedProteins = ['any'];
  final List<String> _availableProteins = ProteinPreferences.mealPlanning;
  
  int _mealsPerDay = 1;
  int _totalDays = 5;
  int _uniqueRecipeTypes = 1;
  bool _isGenerating = false;
  bool _isProteinPrefsExpanded = false;
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Auto-collapse protein preferences when tab changes
    _tabController.addListener(() {
      if (_isProteinPrefsExpanded) {
        setState(() {
          _isProteinPrefsExpanded = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Widget _buildSummaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  int _calculateDays(List<MealPlanSummary> entries) {
    if (entries.isEmpty) return 0;
    
    // Calculate total meals and divide by meals per day to get days
    final totalMeals = entries.fold<int>(0, (sum, entry) => sum + entry.count);
    final days = (totalMeals / _mealsPerDay).ceil();
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final mealPlanAsync = ref.watch(mealPlanProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Auto-collapse protein preferences when generating plan
          if (_isProteinPrefsExpanded) {
            setState(() {
              _isProteinPrefsExpanded = false;
            });
          }
          _showPlanConfigDialog();
        },
        label: const Text('Generate Plan'),
        icon: const Icon(Icons.auto_awesome),
      ),
      body: Column(
        children: [
          if (_isGenerating) const LinearProgressIndicator(minHeight: 2),
          // Protein Preferences Section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                // Header - always visible
                InkWell(
                  onTap: () {
                    setState(() {
                      _isProteinPrefsExpanded = !_isProteinPrefsExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Protein Preferences',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Show selected proteins count when collapsed
                        if (!_isProteinPrefsExpanded && _selectedProteins.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedProteins.length == 1 && _selectedProteins.contains('any')
                                  ? 'Any'
                                  : '${_selectedProteins.length} selected',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () {
                            print('Manual refresh triggered');
                            ref.read(mealPlanRefreshProvider.notifier).state++;
                            ref.invalidate(mealPlanProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Refreshing meal plan...')),
                            );
                          },
                          tooltip: 'Refresh Meal Plan',
                        ),
                        Icon(
                          _isProteinPrefsExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                // Collapsible content
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _isProteinPrefsExpanded ? null : 0,
                  child: _isProteinPrefsExpanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _availableProteins.map((protein) {
                              final isSelected = _selectedProteins.contains(protein);
                              return FilterChip(
                                label: Text(
                                  protein.split(' ').map((word) => 
                                    word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
                                  ).join(' '),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      // If selecting a non-"any" protein, remove "any"
                                      if (protein != 'any') {
                                        _selectedProteins.remove('any');
                                      }
                                      _selectedProteins.add(protein);
                                    } else {
                                      _selectedProteins.remove(protein);
                                      // If deselecting "any" and no other proteins selected, add "any" back
                                      if (protein == 'any' && _selectedProteins.isEmpty) {
                                        _selectedProteins.add('any');
                                      }
                                      // Ensure at least one protein is selected
                                      if (_selectedProteins.isEmpty) {
                                        _selectedProteins.add('any');
                                      }
                                    }
                                  });
                                },
                                selectedColor: Colors.green.withOpacity(0.3),
                                checkmarkColor: Colors.green,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              );
                            }).toList(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.calendar_month), text: 'Meal Plan'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Shopping List'),
            ],
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Meal Plan Tab
                mealPlanAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No meal plan found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('Generate a plan to see your meals', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: [
                        // Meal Plan List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemBuilder: (context, i) {
                              final entry = entries[i];
                              final recipe = entry.recipe;
                              final count = entry.count;
                              
                              return Card(
                                child: ListTile(
                                  leading: recipe.imageUrl != null
                                      ? CircleAvatar(backgroundImage: NetworkImage(recipe.imageUrl!))
                                      : const CircleAvatar(child: Icon(Icons.restaurant)),
                                  title: Text(recipe.title),
                                  subtitle: Text('$count meal${count > 1 ? 's' : ''} planned'),
                                  trailing: Chip(
                                    label: Text('$count'),
                                    backgroundColor: Colors.blue.shade100,
                                    labelStyle: TextStyle(color: Colors.blue.shade700),
                                  ),
                                  onTap: () {
                                    // Auto-collapse protein preferences when tapping meal plan items
                                    if (_isProteinPrefsExpanded) {
                                      setState(() {
                                        _isProteinPrefsExpanded = false;
                                      });
                                    }
                                    // You can add more meal plan item functionality here
                                  },
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemCount: entries.length,
                          ),
                        ),
                        // Plan Summary
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Plan Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(Icons.restaurant, '${entries.length} unique recipe types'),
                              const SizedBox(height: 6),
                              _buildSummaryRow(Icons.local_dining, '${entries.fold<int>(0, (sum, entry) => sum + entry.count)} total meals'),
                              const SizedBox(height: 6),
                              _buildSummaryRow(Icons.calendar_today, 'Over ${_calculateDays(entries)} days'),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
                // Shopping List Tab
                _ShoppingListTab(
                  onItemTap: () {
                    // Auto-collapse protein preferences when tapping shopping list items
                    if (_isProteinPrefsExpanded) {
                      setState(() {
                        _isProteinPrefsExpanded = false;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPlanConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Plan Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Meals per day:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _mealsPerDay.toDouble(),
                        min: 1,
                        max: 3,
                        divisions: 2,
                        onChanged: (value) => setDialogState(() => _mealsPerDay = value.round()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_mealsPerDay',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('How many days needed:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _totalDays.toDouble(),
                        min: 3,
                        max: 14,
                        divisions: 11,
                        onChanged: (value) => setDialogState(() => _totalDays = value.round()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_totalDays',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Unique recipe types needed:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _uniqueRecipeTypes.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (value) => setDialogState(() => _uniqueRecipeTypes = value.round()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_uniqueRecipeTypes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Plan Summary:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                      const SizedBox(height: 4),
                      Text('$_uniqueRecipeTypes unique recipe types'),
                      Text('${_mealsPerDay * _totalDays} total meals'),
                      Text('Over $_totalDays days'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isGenerating ? null : () async {
                Navigator.pop(context);
                setState(() => _isGenerating = true);
                
                try {
                  final config = {
                    'proteinPreferences': _selectedProteins,
                    'uniqueRecipeTypes': _uniqueRecipeTypes,
                    'totalDays': _totalDays,
                    'mealsPerDay': _mealsPerDay,
                  };
                  try {
                    final newPlanId = await ref.refresh(generatePlanProvider(config).future);
                    
                    // Use the returned plan ID to confirm the plan was created
                    print('New meal plan created with ID: $newPlanId');
                  } catch (e) {
                    print('Error during meal plan generation: $e');
                    throw e; // Re-throw to show error to user
                  }
                  
                  // Ensure the database operation is fully complete before refreshing
                  print('Waiting for database commit...');
                  
                  print('Triggering meal plan refresh...');
                  ref.read(mealPlanRefreshProvider.notifier).state++;
                  
      // Also refresh shopping list since it's auto-generated
      ref.invalidate(shoppingListProvider);
      ref.read(shoppingListRefreshProvider.notifier).state++;
                  
                  print('Refresh trigger value: ${ref.read(mealPlanRefreshProvider)}');
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Weekly plan and shopping list generated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to generate plan: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isGenerating = false);
                  }
                }
              },
              child: _isGenerating 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}


class _ShoppingListTab extends ConsumerWidget {
  const _ShoppingListTab({this.onItemTap});
  final VoidCallback? onItemTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListProvider);
    final homeInventoryAsync = ref.watch(homeInventoryStreamProvider);
    
    return Column(
      children: [
        Expanded(
          child: itemsAsync.when(
            data: (items) {
              return homeInventoryAsync.when(
                data: (homeItems) {
                  final grouped = _groupByStore(items);
                  
                  // Add home inventory as a special section
                  if (homeItems.isNotEmpty) {
                    grouped['🏠 Home'] = homeItems.map((item) => ShoppingListItem(
                      id: item.id,
                      ingredientName: item.ingredientName,
                      storeId: null,
                      storeName: 'Home',
                      unit: item.unit,
                      qty: item.quantity,
                      purchased: false,
                    )).toList();
                  }
                  
                  if (items.isEmpty && homeItems.isEmpty) {
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
              
              // Sort stores: Home first, then named stores, then "No Store" at the end
              final sortedEntries = grouped.entries.toList()
                ..sort((a, b) {
                  if (a.key == '🏠 Home') return -1;
                  if (b.key == '🏠 Home') return 1;
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
                  final isHome = storeName == '🏠 Home';
                  
                  return Card(
                    elevation: isNoStore ? 2 : 1,
                    color: isNoStore ? Colors.orange.shade50 : (isHome ? Colors.green.shade50 : null),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Icon(
                            isHome ? Icons.home : (isNoStore ? Icons.warning_amber : Icons.store),
                            color: isHome ? Colors.green : (isNoStore ? Colors.orange : Colors.blue),
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
                            backgroundColor: isHome ? Colors.green.shade100 : (isNoStore ? Colors.orange.shade100 : Colors.blue.shade100),
                            labelStyle: TextStyle(
                              color: isHome ? Colors.green.shade700 : (isNoStore ? Colors.orange.shade700 : Colors.blue.shade700),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      initiallyExpanded: i == 0,
                      children: list.map((item) => _ShoppingItemTile(item: item, onTap: onItemTap)).toList(),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: sortedEntries.length,
              );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error loading home inventory: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
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
  const _ShoppingItemTile({required this.item, this.onTap});
  final ShoppingListItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: CheckboxListTile(
        value: item.purchased,
        onChanged: (_) => ref.read(togglePurchasedProvider(item.id).future),
        title: Text(item.ingredientName),
        subtitle: Row(
          children: [
            if (item.qty != null) Text('${item.qty} '),
            if (item.unit != null) Text(item.unit!),
          ],
        ),
      ),
    );
  }
}
