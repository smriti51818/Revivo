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

/// Carries what's needed to finish signing in once the code is confirmed —
/// passed as router `extra`, kept only in memory for this navigation.
class ConfirmCodeArgs {
  const ConfirmCodeArgs({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  final String email;
  final String password;
  final String name;
  final UserRole role;
}

/// Shown when Cognito requires email confirmation before sign-in — i.e. the
/// pre-sign-up auto-confirm trigger isn't deployed (yet). Confirms the code
/// Cognito emailed, then signs the user straight in.
class ConfirmCodeScreen extends ConsumerStatefulWidget {
  const ConfirmCodeScreen({super.key, required this.args});

  final ConfirmCodeArgs args;

  @override
  ConsumerState<ConfirmCodeScreen> createState() => _ConfirmCodeScreenState();
}

class _ConfirmCodeScreenState extends ConsumerState<ConfirmCodeScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      _toast('Enter the code from your email');
      return;
    }

    setState(() => _loading = true);
    try {
      final service = ref.read(cognitoServiceProvider);
      await service.confirmSignUp(email: widget.args.email, code: code);
      // Reconcile the stored role to the persona the user picked at sign-up.
      final result = await service.signInWithRole(
        email: widget.args.email,
        password: widget.args.password,
        desiredRole: widget.args.role.value,
      );
      if (!mounted) return;
      final role = widget.args.role;
      ref.read(sessionProvider.notifier).setAuthenticated(
            name: result.name.isEmpty ? widget.args.name : result.name,
            email: result.email.isEmpty ? widget.args.email : result.email,
            role: role,
            idToken: result.idToken,
            userId: result.sub,
          );
      context.go(role.homeRoute);
    } on AuthException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref
          .read(cognitoServiceProvider)
          .resendConfirmationCode(email: widget.args.email);
      if (mounted) _toast('A new code has been sent to your email');
    } on AuthException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
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
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            const SizedBox(height: 8),
            const HugeIcon(icon: HugeIcons.strokeRoundedMail01,
                size: 48, color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Enter the 6-digit code sent to',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              widget.args.email,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 6,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(hintText: '000000'),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Verify & continue',
              loading: _loading,
              onPressed: _confirm,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: _resending ? null : _resend,
                child: Text(
                  _resending ? 'Sending...' : "Didn't get a code? Resend",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
