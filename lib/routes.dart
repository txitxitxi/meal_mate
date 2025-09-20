import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/recipes_page.dart';
import 'pages/public_recipes_page.dart';
import 'pages/stores_page.dart';
import 'pages/weekly/weekly_plan_page.dart';

GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RootShell(),
      routes: [
        GoRoute(path: 'public-recipes', builder: (c, s) => const PublicRecipesPage()),
        GoRoute(path: 'recipes', builder: (c, s) => const RecipesPage()),
        GoRoute(path: 'stores', builder: (c, s) => const StoresPage()),
        GoRoute(path: 'weekly', builder: (c, s) => const WeeklyPlanPage()),
      ],
    ),
  ],
  initialLocation: '/recipes',
);

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final _tabs = ['/public-recipes', '/recipes', '/stores', '/weekly'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const PublicRecipesPage(),
        const RecipesPage(),
        const StoresPage(),
        const WeeklyPlanPage(),
      ][_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.public), label: 'Public Recipes'),
          NavigationDestination(icon: Icon(Icons.book), label: 'My Recipe'),
          NavigationDestination(icon: Icon(Icons.store_mall_directory), label: 'Stores'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Meal Prep'),
        ],
        onDestinationSelected: (i) {
          setState(() => _index = i);
          context.go(_tabs[i]);
        },
      ),
    );
  }
}
