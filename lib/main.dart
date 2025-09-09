import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_router.dart';
import 'services/supabase_service.dart';


// flutter run -d "iPhone 16 Pro Max"
// --dart-define=SUPABASE_URL=https://hqnorxqkdgosvrjcftlf.supabase.co
// --dart-define=SUPABASE_ANON_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhxbm9yeHFrZGdvc3ZyamNmdGxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5NTcxMjgsImV4cCI6MjA3MjUzMzEyOH0.MVjT8TzXQhZ9T10svYvVjUAKUKGnn41KR04JscL_6e4'




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase from --dart-define to avoid committing secrets.
  final url = const String.fromEnvironment('SUPABASE_URL');
  final anon = const String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(url: url, anonKey: anon);

  runApp(const ProviderScope(child: MealMateApp()));
}

class MealMateApp extends ConsumerWidget {
  const MealMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Meal Mate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3AAFA9)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
