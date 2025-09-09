import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey: SupabaseService.anonKey,
    realtimeClientOptions: const RealtimeClientOptions(heartbeatIntervalMs: 15_000),
  );

  runApp(const ProviderScope(child: MealMateApp()));
}

class MealMateApp extends ConsumerWidget {
  const MealMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createRouter();
    return MaterialApp.router(
      title: 'Meal Mate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      routerConfig: router,
    );
  }
}
