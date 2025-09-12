import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'recipes_page.dart';
import 'stores_page.dart';
import 'weekly/weekly_plan_page.dart';
import 'shopping/shopping_list_page.dart';
import '../widgets/custom_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final _tabs = ['/home/recipes', '/home/stores', '/home/weekly', '/home/shopping'];
  final _pageTitles = ['Recipes', 'Stores', 'Meal Prep', 'Shopping List'];

  @override
  void initState() {
    super.initState();
    // Set initial tab based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = GoRouterState.of(context).matchedLocation;
      final tabIndex = _tabs.indexOf(location);
      if (tabIndex != -1 && tabIndex != _index) {
        setState(() => _index = tabIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: CustomHeader(pageTitle: _pageTitles[_index]),
      body: IndexedStack(
        index: _index,
        children: const [
          RecipesPage(),
          StoresPage(),
          WeeklyPlanPage(),
          ShoppingListPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book), label: 'Recipes'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Stores'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Meal Prep'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
        ],
        onDestinationSelected: (i) {
          setState(() => _index = i);
          // Don't navigate, just switch the tab content
        },
      ),
    );
  }
}
