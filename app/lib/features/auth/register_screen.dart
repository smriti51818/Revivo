import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_role.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';

/// Registration. Mocked in M1; M3 creates a Cognito user with `custom:role`.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.role});

  final UserRole? role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  UserRole get _role => widget.role ?? UserRole.vendor;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    ref.read(sessionProvider.notifier).signIn(
          name: _name.text.trim().isEmpty ? _role.label : _name.text.trim(),
          email: _email.text.trim(),
          role: _role,
        );
    context.go(_role.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            Text(
              'Register as ${_role.label}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Join 5,000+ others reducing food waste today.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _field(_name, 'Full name', Icons.person_outline),
            const SizedBox(height: AppSpacing.lg),
            _field(_email, 'Email address', Icons.mail_outline,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: AppSpacing.lg),
            _field(_password, 'Password', Icons.lock_outline, obscure: true),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Create account',
              loading: _loading,
              onPressed: _register,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: const Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Log in',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(prefixIcon: Icon(icon, size: 20)),
        ),
      ],
    );
  }
}
