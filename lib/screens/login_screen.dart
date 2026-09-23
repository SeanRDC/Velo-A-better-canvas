// Authentication Screen for Canvas login
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/error_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    
    // Simulate OAuth / API token validation delay
    await Future.delayed(const Duration(milliseconds: 900));
    
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/dashboard');
    }
  }

  void _showErrorPreview() {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        message: "We couldn't reach Canvas. Check your connection and try signing in again.",
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            children: [
              const Spacer(),
              // Brand
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  LucideIcons.graduationCap,
                  size: 32,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'A Better Canvas',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your coursework, planned for you.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const Spacer(),
              // Auth Actions
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Log in with Canvas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shieldCheck, size: 14, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Secure OAuth 2.0 — we never store your password',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _showErrorPreview,
                child: Text(
                  'Preview the connection-error dialog',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}