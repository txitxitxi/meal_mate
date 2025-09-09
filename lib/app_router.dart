// lib/app_router.dart
import 'dart:async'; // <-- add this

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/recipes_page.dart';

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

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
  final authStream = ref.watch(authStateChangesProvider.stream);
  final client = Supabase.instance.client;

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authStream),
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'recipes',
            name: 'recipes',
            builder: (context, state) => const RecipesPage(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final session = client.auth.currentSession;
      final atLogin = state.matchedLocation == '/login'; // <-- use matchedLocation

      if (session == null) {
        return atLogin ? null : '/login';
      }
      if (atLogin) return '/home';
      return null;
    },
  );
});
