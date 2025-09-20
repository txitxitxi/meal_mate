// lib/pages/weekly/weekly_plan_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/weekly_shopping_providers.dart';
import '../../models/moduels.dart';

class WeeklyPlanPage extends ConsumerStatefulWidget {
  const WeeklyPlanPage({super.key});

  @override
  ConsumerState<WeeklyPlanPage> createState() => _WeeklyPlanPageState();
}

class _WeeklyPlanPageState extends ConsumerState<WeeklyPlanPage> with TickerProviderStateMixin {
  final List<String> _selectedProteins = ['any'];
  final List<String> _availableProteins = [
    'any',
    'chicken',
    'beef', 
    'pork',
    'fish',
    'seafood',
    'vegetarian',
    'vegan'
  ];
  
  int _mealsPerDay = 1;
  int _totalDays = 5;
  int _uniqueRecipeTypes = 1;
  bool _isGenerating = false;
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mealPlanAsync = ref.watch(mealPlanProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanConfigDialog(),
        label: const Text('Generate Plan'),
        icon: const Icon(Icons.auto_awesome),
      ),
      body: Column(
        children: [
          if (_isGenerating) const LinearProgressIndicator(minHeight: 2),
          // Protein Preferences Section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Protein Preferences',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _availableProteins.map((protein) {
                      final isSelected = _selectedProteins.contains(protein);
                      return FilterChip(
                        label: Text(protein.split(' ').map((word) => 
                          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
                        ).join(' ')),
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
                      );
                    }).toList(),
                  ),
                ],
              ),
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
                    
                    return ListView.separated(
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
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: entries.length,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
                // Shopping List Tab
                _ShoppingListTab(),
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
                Slider(
                  value: _mealsPerDay.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  label: '$_mealsPerDay',
                  onChanged: (value) => setDialogState(() => _mealsPerDay = value.round()),
                ),
                const SizedBox(height: 20),
                const Text('How many days needed:', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _totalDays.toDouble(),
                  min: 3,
                  max: 14,
                  divisions: 11,
                  label: '$_totalDays',
                  onChanged: (value) => setDialogState(() => _totalDays = value.round()),
                ),
                const SizedBox(height: 20),
                const Text('Unique recipe types needed:', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _uniqueRecipeTypes.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_uniqueRecipeTypes',
                  onChanged: (value) => setDialogState(() => _uniqueRecipeTypes = value.round()),
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
  const _ShoppingListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListProvider);
    
    return Column(
      children: [
        Expanded(
          child: itemsAsync.when(
            data: (items) {
              final grouped = _groupByStore(items);
              
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
