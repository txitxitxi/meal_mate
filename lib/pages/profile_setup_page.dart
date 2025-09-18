import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _handleController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isPrivate = false;
  bool _loading = false;
  String? _error;
  String? _handleError;

  @override
  void dispose() {
    _handleController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _checkHandleAvailability(String handle) async {
    if (handle.length < 3) {
      setState(() => _handleError = 'Handle must be at least 3 characters');
      return;
    }

    final authController = ref.read(authControllerProvider);
    final isAvailable = await authController.isHandleAvailable(handle);
    
    setState(() {
      _handleError = isAvailable ? null : 'This handle is already taken';
    });
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate() || _handleError != null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authController = ref.read(authControllerProvider);
      await authController.createProfile(
        handle: _handleController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty 
            ? null 
            : _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty 
            ? null 
            : _bioController.text.trim(),
        isPrivate: _isPrivate,
      );

      // Profile created successfully, navigation will be handled by router
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Header
                Text(
                  'Set up your profile',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a unique handle and tell us about yourself',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Handle field
                TextFormField(
                  controller: _handleController,
                  decoration: InputDecoration(
                    labelText: 'Handle *',
                    hintText: 'e.g., chef_alex',
                    prefixText: '@',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _handleError,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Handle is required';
                    }
                    if (value.length < 3 || value.length > 20) {
                      return 'Handle must be 3-20 characters';
                    }
                    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                      return 'Handle can only contain lowercase letters, numbers, and underscores';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.length >= 3) {
                      _checkHandleAvailability(value.trim().toLowerCase());
                    } else {
                      setState(() => _handleError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Display name field
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'How others will see your name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bio field
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about your cooking interests...',
                    prefixIcon: const Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Private profile toggle
                SwitchListTile(
                  title: const Text('Private Profile'),
                  subtitle: const Text('Only you can see your recipes and profile'),
                  value: _isPrivate,
                  onChanged: (value) {
                    setState(() => _isPrivate = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Error message
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Spacer(),

                // Create Profile Button
                FilledButton(
                  onPressed: (_loading || _handleError != null) ? null : _createProfile,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
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
                      : const Text(
                          'Create Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 16),

                // Sign out option
                TextButton(
                  onPressed: _loading ? null : () async {
                    final authController = ref.read(authControllerProvider);
                    await authController.signOut();
                  },
                  child: const Text('Sign out and try a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
