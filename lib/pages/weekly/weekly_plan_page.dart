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

class _WeeklyPlanPageState extends ConsumerState<WeeklyPlanPage> {
  final List<String> _selectedProteins = ['none'];
  final List<String> _availableProteins = [
    'none',
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

  @override
  Widget build(BuildContext context) {
    final weeklyAsync = ref.watch(weeklyPlanProvider);

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
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Protein Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your preferred proteins for this week:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableProteins.map((protein) {
                      final isSelected = _selectedProteins.contains(protein);
                      return FilterChip(
                        label: Text(protein.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedProteins.add(protein);
                            } else {
                              _selectedProteins.remove(protein);
                              // Ensure at least one protein is selected
                              if (_selectedProteins.isEmpty) {
                                _selectedProteins.add('none');
                              }
                            }
                          });
                        },
                        selectedColor: Colors.green.withOpacity(0.3),
                        checkmarkColor: Colors.green,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: weeklyAsync.when(
              data: (entries) {
                // Show a 7-day grid starting today
                final start = DateTime.now();
                final days = List.generate(
                  7,
                  (i) => DateTime(start.year, start.month, start.day).add(Duration(days: i)),
                );

                if (entries.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No weekly plan found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Generate a plan to see your meals', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                
                // Group recipes by type and count occurrences
                final recipeCounts = <String, int>{};
                final recipeDetails = <String, WeeklyEntry>{};
                
                for (final entry in entries) {
                  final recipeTitle = entry.recipe.title;
                  recipeCounts[recipeTitle] = (recipeCounts[recipeTitle] ?? 0) + 1;
                  recipeDetails[recipeTitle] = entry;
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, i) {
                    final recipeTitle = recipeCounts.keys.elementAt(i);
                    final count = recipeCounts[recipeTitle]!;
                    final recipe = recipeDetails[recipeTitle]!.recipe;
                    
                    return Card(
                      child: ListTile(
                        leading: recipe.imageUrl != null
                            ? CircleAvatar(backgroundImage: NetworkImage(recipe.imageUrl!))
                            : const CircleAvatar(child: Icon(Icons.restaurant)),
                        title: Text(recipeTitle),
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
                  itemCount: recipeCounts.length,
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
                  await ref.refresh(generatePlanProvider(config).future);
                  ref.invalidate(weeklyPlanProvider);
                  // Also refresh shopping list since it's auto-generated
                  ref.invalidate(shoppingListProvider);
                  
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

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmt(DateTime d) => '${d.month}/${d.day}';
