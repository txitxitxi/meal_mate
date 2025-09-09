import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/recipes/recipes_page.dart';
import 'pages/stores/stores_page.dart';
import 'pages/weekly/weekly_plan_page.dart';
import 'pages/shopping/shopping_list_page.dart';

GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RootShell(),
      routes: [
        GoRoute(path: 'recipes', builder: (c, s) => const RecipesPage()),
        GoRoute(path: 'stores', builder: (c, s) => const StoresPage()),
        GoRoute(path: 'weekly', builder: (c, s) => const WeeklyPlanPage()),
        GoRoute(path: 'shopping', builder: (c, s) => const ShoppingListPage()),
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
  final _tabs = ['/recipes', '/stores', '/weekly', '/shopping'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Router.of(context).routerDelegate.currentConfiguration.uri.toString().contains('/recipes')
          ? const RecipesPage()
          : Router.of(context).routerDelegate.currentConfiguration.uri.toString().contains('/stores')
              ? const StoresPage()
              : Router.of(context).routerDelegate.currentConfiguration.uri.toString().contains('/weekly')
                  ? const WeeklyPlanPage()
                  : const ShoppingListPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book), label: 'Recipes'),
          NavigationDestination(icon: Icon(Icons.store_mall_directory), label: 'Stores'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Weekly'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
        ],
        onDestinationSelected: (i) {
          setState(() => _index = i);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go(_tabs[i]);
          });
        },
      ),
    );
  }
}
