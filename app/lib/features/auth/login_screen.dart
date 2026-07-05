import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/providers.dart';
import '../../core/auth/cognito_service.dart';
import '../../core/models/user_role.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';

/// Login screen — authenticates against Amazon Cognito (or a local mock when
/// `useLiveApi` is off).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.role});

  final UserRole? role;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  UserRole get _role => widget.role ?? UserRole.vendor;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      _toast('Enter your email and password');
      return;
    }

    final config = ref.read(appConfigProvider);
    setState(() => _loading = true);
    try {
      if (config.useLiveApi) {
        final result = await ref
            .read(cognitoServiceProvider)
            .signIn(email: email, password: password);
        if (!mounted) return;
        final role = UserRole.fromValue(result.role) ?? _role;
        ref.read(sessionProvider.notifier).setAuthenticated(
              name: result.name.isEmpty ? role.label : result.name,
              email: result.email.isEmpty ? email : result.email,
              role: role,
              idToken: result.idToken,
              userId: result.sub,
            );
        context.go(role.homeRoute);
      } else {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        ref
            .read(sessionProvider.notifier)
            .signIn(name: _role.label, email: email, role: _role);
        context.go(_role.homeRoute);
      }
    } on AuthException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Revivo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Reduce waste, grow business',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _label('Email address'),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.mail_outline, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('Password'),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Login as ${_role.label}',
              loading: _loading,
              onPressed: _login,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: _socialButton(Icons.g_mobiledata, 'Google')),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _socialButton(Icons.apple, 'Apple')),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () => context.push('/register', extra: _role),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _socialButton(IconData icon, String label) => OutlinedButton.icon(
        onPressed: () => _toast('$label sign-in coming soon'),
        icon: Icon(icon, size: 22, color: AppColors.textPrimary),
        label: Text(label),
      );
}
