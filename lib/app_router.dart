// lib/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'manager/login_manager.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/recipes_page.dart';

// LoginManager 的 Provider
final loginManagerProvider = Provider<LoginManager>((ref) {
  return LoginManager();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final loginManager = ref.read(loginManagerProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: loginManager,
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
      final isLoggedIn = loginManager.isLoggedIn;
      final atLogin = state.matchedLocation == '/login';

      // 如果未登录且不在登录页，跳转到登录页
      if (!isLoggedIn && !atLogin) {
        return '/login';
      }

      // 如果已登录且在登录页，跳转到主页
      if (isLoggedIn && atLogin) {
        return '/home';
      }

      return null;
    },
  );
});
