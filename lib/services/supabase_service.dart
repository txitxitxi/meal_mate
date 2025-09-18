import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class SupabaseService {
  static const supabaseUrl = 'https://hqnorxqkdgosvrjcftlf.supabase.co';
  static const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhxbm9yeHFrZGdvc3ZyamNmdGxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5NTcxMjgsImV4cCI6MjA3MjUzMzEyOH0.MVjT8TzXQhZ9T10svYvVjUAKUKGnn41KR04JscL_6e4';

  static SupabaseClient get client => Supabase.instance.client;

  // Authentication methods
  static Future<AuthResponse> signInWithApple() async {
    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException(
          'Could not find ID Token from Apple SignIn.');
    }

    return client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // User profile methods
  static Future<UserProfile?> getCurrentUserProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromMap(response);
  }

  static Future<UserProfile> createUserProfile({
    required String handle,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool isPrivate = false,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final profileData = {
      'user_id': user.id,
      'handle': handle,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'is_private': isPrivate,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final response = await client
        .from('profiles')
        .insert(profileData)
        .select()
        .single();

    return UserProfile.fromMap(response);
  }

  static Future<UserProfile> updateUserProfile({
    String? handle,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isPrivate,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (handle != null) updateData['handle'] = handle;
    if (displayName != null) updateData['display_name'] = displayName;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    if (bio != null) updateData['bio'] = bio;
    if (isPrivate != null) updateData['is_private'] = isPrivate;

    final response = await client
        .from('profiles')
        .update(updateData)
        .eq('user_id', user.id)
        .select()
        .single();

    return UserProfile.fromMap(response);
  }

  static Future<bool> isHandleAvailable(String handle) async {
    final response = await client
        .from('profiles')
        .select('handle')
        .eq('handle', handle)
        .maybeSingle();

    return response == null;
  }

  // Helper method to generate nonce for Apple Sign In
  static String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}
