import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/recipes_page.dart';
import 'pages/public_recipes_page.dart';
import 'pages/stores_page.dart';
import 'pages/meal_plan/meal_plan_page.dart';
import 'providers/auth_providers.dart';
import 'services/supabase_service.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authChanges = SupabaseService.client.auth.onAuthStateChange;

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authChanges),
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'public-recipes',
            name: 'public-recipes',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: 'recipes',
            name: 'recipes',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: 'stores',
            name: 'stores',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: 'weekly',
            name: 'weekly',
            builder: (context, state) => const HomePage(),
          ),
        ],
      ),
      // Keep these routes for backward compatibility, but redirect to /home versions
      GoRoute(
        path: '/public-recipes',
        redirect: (context, state) => '/home/public-recipes',
      ),
      GoRoute(
        path: '/recipes',
        redirect: (context, state) => '/home/recipes',
      ),
      GoRoute(
        path: '/stores',
        redirect: (context, state) => '/home/stores',
      ),
      GoRoute(
        path: '/weekly',
        redirect: (context, state) => '/home/weekly',
      ),
    ],
    redirect: (context, state) async {
      final container = ProviderScope.containerOf(context);
      final authState = await container.read(authStateProvider.future);
      final profile = await container.read(userProfileProvider.future);
      
      final session = authState.session;
      final currentPath = state.matchedLocation;
      
      // Not authenticated
      if (session == null) {
        if (currentPath == '/login') return null;
        return '/login';
      }
      
      // Authenticated but no profile yet
      if (profile == null) {
        if (currentPath == '/profile-setup' || currentPath == '/login') return null;
        return '/profile-setup';
      }
      
      // Authenticated with profile, redirect away from auth pages
      if (currentPath == '/login' || currentPath == '/profile-setup') {
        return '/home';
      }
      
      return null;
    },
  );
});
