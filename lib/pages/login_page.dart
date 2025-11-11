import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  bool _appleLoading = false;
  String? _error;

  Future<void> _signInWithEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authController = ref.read(authControllerProvider);
      await authController.signInWithEmail(
        _emailCtrl.text.trim(),
        _pwdCtrl.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailCtrl.text.isEmpty) {
      setState(() => _error = 'Enter email first');
      return;
    }
    if (_pwdCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authController = ref.read(authControllerProvider);
      await authController.signUpWithEmail(
        _emailCtrl.text.trim(),
        _pwdCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Check your email for confirmation link'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _appleLoading = true;
      _error = null;
    });

    try {
      final authController = ref.read(authControllerProvider);
      await authController.signInWithApple();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Apple Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Title
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Meal Mate',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Plan meals, create recipes, shop smarter',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // Apple Sign In Button (iOS only)
              if (Platform.isIOS) ...[
                SizedBox(
                  height: 56,
                  child: CupertinoButton(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(28),
                    onPressed: _appleLoading ? null : _signInWithApple,
                    child: _appleLoading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.app_badge,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Apple',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Email/Password Form
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pwdCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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

              // Sign In Button
              FilledButton(
                onPressed: _loading ? null : _signInWithEmail,
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
                        'Sign In',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 16),

              // Sign Up Button
              OutlinedButton(
                onPressed: _loading ? null : _signUpWithEmail,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
