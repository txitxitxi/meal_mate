import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'recipes_page.dart';
import 'public_recipes_page.dart';
import 'stores_page.dart';
import 'weekly/weekly_plan_page.dart';
import '../providers/auth_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;
  final _tabs = ['/home/public-recipes', '/home/recipes', '/home/stores', '/home/weekly'];
  final _pageTitles = ['Public Recipes', 'My Recipe', 'Stores', 'Meal Prep'];

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
    final userProfile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_index]),
        actions: [
          // Profile menu
          userProfile.when(
            data: (profile) => PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: profile?.avatarUrl != null 
                    ? NetworkImage(profile!.avatarUrl!) 
                    : null,
                child: profile?.avatarUrl == null 
                    ? Text(
                        profile?.displayName?.isNotEmpty == true 
                            ? profile!.displayName![0].toUpperCase()
                            : profile?.handle[0].toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(profile?.displayName ?? profile?.handle ?? 'User'),
                    subtitle: Text('@${profile?.handle ?? 'user'}'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'signout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) async {
                switch (value) {
                  case 'profile':
                    // TODO: Navigate to profile page
                    break;
                  case 'settings':
                    // TODO: Navigate to settings page
                    break;
                  case 'signout':
                    final authController = ref.read(authControllerProvider);
                    await authController.signOut();
                    break;
                }
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () async {
                final authController = ref.read(authControllerProvider);
                await authController.signOut();
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          PublicRecipesPage(),
          RecipesPage(),
          StoresPage(),
          WeeklyPlanPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.public), label: 'Public Recipes'),
              NavigationDestination(icon: Icon(Icons.book), label: 'My Recipe'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Stores'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Meal Prep'),
        ],
        onDestinationSelected: (i) {
          setState(() => _index = i);
          // Don't navigate, just switch the tab content
        },
      ),
    );
  }
}
