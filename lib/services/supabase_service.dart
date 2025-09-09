import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const supabaseUrl = 'https://hqnorxqkdgosvrjcftlf.supabase.co';
  static const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhxbm9yeHFrZGdvc3ZyamNmdGxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5NTcxMjgsImV4cCI6MjA3MjUzMzEyOH0.MVjT8TzXQhZ9T10svYvVjUAKUKGnn41KR04JscL_6e4';

  static SupabaseClient get client => Supabase.instance.client;
}
