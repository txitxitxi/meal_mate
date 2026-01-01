// lib/pages/meal_plan/meal_plan_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/meal_plan_providers.dart';
import '../../models/moduels.dart';
import '../../utils/protein_preferences.dart';
import '../../utils/logger.dart';

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
  
  ColorScheme get _colorScheme => Theme.of(context).colorScheme;
  
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
    final accentColor = _colorScheme.primary;
    final accentTextColor = _colorScheme.onPrimaryContainer;
    return Row(
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: accentTextColor,
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
    final scheme = _colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'generate-plan-fab',
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
                              color: scheme.secondaryContainer.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedProteins.length == 1 && _selectedProteins.contains('any')
                                  ? 'Any'
                                  : '${_selectedProteins.length} selected',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () {
                            logDebug('Manual refresh triggered');
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
                                selectedColor: scheme.primaryContainer.withValues(alpha: 0.7),
                                checkmarkColor: scheme.onPrimaryContainer,
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
                                    backgroundColor: scheme.primaryContainer.withValues(alpha: 0.7),
                                    labelStyle: TextStyle(color: scheme.onPrimaryContainer),
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
                            color: scheme.primaryContainer.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: scheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Plan Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onPrimaryContainer,
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
        builder: (context, setDialogState) {
          final dialogScheme = Theme.of(context).colorScheme;
          return AlertDialog(
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: dialogScheme.primary,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: dialogScheme.primary,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: dialogScheme.primary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dialogScheme.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Plan Summary:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dialogScheme.onPrimaryContainer,
                        ),
                      ),
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
                    logDebug('New meal plan created with ID: $newPlanId');
                  } catch (e) {
                    logDebug('Error during meal plan generation: $e');
                    rethrow;
                  }
                  
                  // Ensure the database operation is fully complete before refreshing
                  logDebug('Waiting for database commit...');
                  
                  logDebug('Triggering meal plan refresh...');
                  ref.read(mealPlanRefreshProvider.notifier).state++;
                  
      // Also refresh shopping list since it's auto-generated
      ref.invalidate(shoppingListProvider);
      ref.read(shoppingListRefreshProvider.notifier).state++;
                  
                  logDebug('Refresh trigger value: ${ref.read(mealPlanRefreshProvider)}');
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Weekly plan and shopping list generated successfully!'),
                        backgroundColor: dialogScheme.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to generate plan: $e'),
                        backgroundColor: dialogScheme.error,
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
        );
        },
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
    final scheme = Theme.of(context).colorScheme;
    final storeColor = scheme.primary;
    final storeContainer = scheme.primaryContainer;
    final onStoreContainer = scheme.onPrimaryContainer;
    final homeColor = scheme.secondary;
    final homeContainer = scheme.secondaryContainer;
    final onHomeContainer = scheme.onSecondaryContainer;
    final noStoreColor = scheme.tertiary;
    final noStoreContainer = scheme.tertiaryContainer;
    final onNoStoreContainer = scheme.onTertiaryContainer;
    
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
                  
                  final cardColor = isNoStore
                      ? noStoreContainer.withValues(alpha: 0.3)
                      : (isHome ? homeContainer.withValues(alpha: 0.3) : null);
                  final iconColor = isHome ? homeColor : (isNoStore ? noStoreColor : storeColor);
                  final chipBackground = isHome
                      ? homeContainer.withValues(alpha: 0.7)
                      : (isNoStore ? noStoreContainer.withValues(alpha: 0.7) : storeContainer.withValues(alpha: 0.7));
                  final chipTextColor = isHome
                      ? onHomeContainer
                      : (isNoStore ? onNoStoreContainer : onStoreContainer);

                  return Card(
                    elevation: isNoStore ? 2 : 1,
                    color: cardColor,
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Icon(
                            isHome ? Icons.home : (isNoStore ? Icons.warning_amber : Icons.store),
                            color: iconColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            storeName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isNoStore ? noStoreColor : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('${list.length} items'),
                            backgroundColor: chipBackground,
                            labelStyle: TextStyle(
                              color: chipTextColor,
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
    // If storeName is null but item is checked, it's from home inventory
    final storeName = it.storeName ?? (it.purchased ? '🏠 Home' : 'No Store');
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
