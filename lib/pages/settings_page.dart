// lib/pages/settings_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../providers/recipe_providers.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _loading = false;
  UserProfile? _currentProfile;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newDisplayName = _displayNameController.text.trim();
    final finalDisplayName = newDisplayName.isEmpty ? null : newDisplayName;
    
    // If display name hasn't changed, just go back
    if (finalDisplayName == _currentProfile?.displayName) {
      if (mounted) context.pop();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authController = ref.read(authControllerProvider);
      final user = SupabaseService.client.auth.currentUser;
      final userId = user?.id;
      
      await authController.updateProfile(displayName: finalDisplayName);

      // Invalidate author profile provider for this user (so recipe author names update)
      if (userId != null) {
        ref.invalidate(authorProfileProvider(userId));
        // Also invalidate public recipes to force refresh
        ref.invalidate(publicRecipesStreamProvider);
      }

      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Pop back to previous page
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _error;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: profileAsync.when(
        data: (profile) {
          // Initialize controller with current profile display name
          if (profile != null && _currentProfile?.displayName != profile.displayName) {
            _currentProfile = profile;
            if (_displayNameController.text != (profile.displayName ?? '')) {
              _displayNameController.text = profile.displayName ?? '';
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Update Display Name',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Change how your name appears. Leave empty to use your handle.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Handle (read-only info)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Handle (Fixed ID)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.alternate_email, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              profile?.handle ?? 'N/A',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Display name field
                  TextFormField(
                    controller: _displayNameController,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'e.g., John Doe',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'This is how your name appears in the app. Leave empty to use your handle.',
                    ),
                    validator: (value) {
                      // Display name is optional, so no validation needed
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Update button
                  ElevatedButton(
                    onPressed: _loading ? null : _updateDisplayName,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Display Name'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cancel button
                  OutlinedButton(
                    onPressed: _loading ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
