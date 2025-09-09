// lib/pages/weekly/weekly_plan_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/weekly_shopping_providers.dart';

class WeeklyPlanPage extends ConsumerWidget {
  const WeeklyPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyPlanProvider);
    final gen = ref.watch(generatePlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Plan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.refresh(generatePlanProvider),
        label: const Text('Generate Plan'),
        icon: const Icon(Icons.auto_awesome),
      ),
      body: Column(
        children: [
          if (gen.isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: weeklyAsync.when(
              data: (entries) {
                // Show a 7-day grid starting today
                final start = DateTime.now();
                final days = List.generate(
                  7,
                  (i) => DateTime(start.year, start.month, start.day).add(Duration(days: i)),
                );

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, i) {
                    final d = days[i];
                    final match = entries.where((e) => _sameDay(e.day, d)).toList();
                    final title = match.isNotEmpty ? match.first.recipe.title : '—';
                    final photo = match.isNotEmpty ? match.first.recipe.photoUrl : null;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_fmt(d), style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Expanded(
                              child: photo != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(photo, fit: BoxFit.cover),
                                    )
                                  : const DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Color(0x11000000),
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                      ),
                                      child: Center(child: Icon(Icons.image)),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
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

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmt(DateTime d) => '${d.month}/${d.day}';
