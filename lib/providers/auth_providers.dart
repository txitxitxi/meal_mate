import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.client.auth.onAuthStateChange;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// User profile provider (from profiles table)
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  return await SupabaseService.getCurrentUserProfile();
});

// User info provider (from users table - has display names)
final userInfoProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final response = await SupabaseService.client
      .from('users')
      .select()
      .eq('id', user.id)
      .maybeSingle();
  
  return response;
});

// Auth controller for authentication actions
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  Future<void> signInWithApple() async {
    try {
      await SupabaseService.signInWithApple();
      // Refresh the user profile after sign in
      _ref.invalidate(userProfileProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await SupabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      _ref.invalidate(userProfileProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await SupabaseService.signUpWithEmail(
        email: email,
        password: password,
      );
      _ref.invalidate(userProfileProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
      _ref.invalidate(userProfileProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile> createProfile({
    required String handle,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool isPrivate = false,
  }) async {
    try {
      final profile = await SupabaseService.createUserProfile(
        handle: handle,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        isPrivate: isPrivate,
      );
      _ref.invalidate(userProfileProvider);
      return profile;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile> updateProfile({
    String? handle,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isPrivate,
  }) async {
    try {
      final profile = await SupabaseService.updateUserProfile(
        handle: handle,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        isPrivate: isPrivate,
      );
      _ref.invalidate(userProfileProvider);
      return profile;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isHandleAvailable(String handle) async {
    return await SupabaseService.isHandleAvailable(handle);
  }
}

// Profile setup state for new users
final profileSetupStateProvider = StateProvider<ProfileSetupState>((ref) {
  return ProfileSetupState.initial;
});

enum ProfileSetupState {
  initial,
  settingUpProfile,
  profileComplete,
  error,
}
