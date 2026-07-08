import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/providers.dart';
import '../../core/auth/cognito_service.dart';
import '../../core/models/user_role.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import 'confirm_code_screen.dart';

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
    final password = _password.text.trim();
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
      if (!mounted) return;
      if (e.code == 'UserNotConfirmedException') {
        try {
          await ref
              .read(cognitoServiceProvider)
              .resendConfirmationCode(email: email);
        } catch (_) {}
        if (!mounted) return;
        context.push(
          '/confirm-code',
          extra: ConfirmCodeArgs(
            email: email,
            password: password,
            name: _role.label,
            role: _role,
          ),
        );
      } else {
        _toast(e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  ({dynamic icon, String verb}) get _roleStyle => switch (_role) {
        UserRole.vendor => (
            icon: HugeIcons.strokeRoundedStore02,
            verb: 'Seller',
          ),
        UserRole.buyer => (
            icon: HugeIcons.strokeRoundedRestaurant02,
            verb: 'Hotel Kitchen',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final rs = _roleStyle;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
          children: [
            const SizedBox(height: 16),
            // ── Brand mark ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLeaf02,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Revivo',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
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

            const SizedBox(height: 32),

            // ── Role badge ──
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: rs.icon,
                      color: AppColors.primaryDark,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Logging in as ${rs.verb}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Email ──
            _label('Email address'),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMail01,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Password ──
            _label('Password'),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedLockKey,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: HugeIcon(
                      icon: _obscure
                          ? HugeIcons.strokeRoundedEye
                          : HugeIcons.strokeRoundedViewOff,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── CTA ──
            PrimaryButton(
              label: 'Login as ${rs.verb}',
              loading: _loading,
              onPressed: _login,
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Register link ──
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

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );
}
