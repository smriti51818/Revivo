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

/// Registration — creates an Amazon Cognito user with `custom:role` (or a local
/// mock when `useLiveApi` is off). The pre-sign-up trigger auto-confirms, so
/// the user is signed straight in. Validates name / email / password up front
/// (matching the pool's password policy) so users get a clear message before
/// the request, and offers to jump to login if the email already exists.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.role});

  final UserRole? role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  UserRole get _role => widget.role ?? UserRole.vendor;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Client-side checks that mirror the Cognito user-pool rules, so the user is
  /// told exactly what's wrong before we make a network call.
  static final _phoneRe = RegExp(r'^[+]?[0-9]{10,15}$');

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Please enter your name.';
    final phone = _phone.text.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.isEmpty || !_phoneRe.hasMatch(phone)) {
      return 'Please enter a valid phone number.';
    }
    final email = _email.text.trim();
    if (!_emailRe.hasMatch(email)) return 'Please enter a valid email address.';
    final pw = _password.text;
    if (pw.length < 8 ||
        !pw.contains(RegExp(r'[a-z]')) ||
        !pw.contains(RegExp(r'[0-9]'))) {
      return 'Password must be at least 8 characters, with a lowercase '
          'letter and a number.';
    }
    return null;
  }

  Future<void> _register() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();

    final config = ref.read(appConfigProvider);
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (config.useLiveApi) {
        final result = await ref.read(cognitoServiceProvider).signUp(
              email: email,
              password: password,
              name: name,
              role: _role.value,
            );
        if (!mounted) return;
        // The role the user just picked is authoritative for registration.
        ref.read(sessionProvider.notifier).setAuthenticated(
              name: result.name.isEmpty ? name : result.name,
              email: result.email.isEmpty ? email : result.email,
              role: _role,
              idToken: result.idToken,
              userId: result.sub,
              refreshToken: result.refreshToken,
              phone: _phone.text.trim(),
            );
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        ref
            .read(sessionProvider.notifier)
            .signIn(name: name, email: email, role: _role);
      }
      context.go(_role.homeRoute);
    } on NeedsConfirmationException catch (e) {
      if (!mounted) return;
      context.push(
        '/confirm-code',
        extra: ConfirmCodeArgs(
          email: e.email,
          password: password,
          name: name,
          role: _role,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'UsernameExistsException') {
        _showExistsDialog(email);
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// A clear next step when the email is already registered — offer to log in
  /// rather than leaving the user stuck on a failed sign-up.
  Future<void> _showExistsDialog(String email) async {
    final goLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account already exists'),
        content: Text(
          '$email is already registered. Log in instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Log in'),
          ),
        ],
      ),
    );
    if (goLogin == true && mounted) context.pop(); // back to the login screen
  }

  @override
  Widget build(BuildContext context) {
    final pwValid = _password.text.length >= 8 &&
        _password.text.contains(RegExp(r'[a-z]')) &&
        _password.text.contains(RegExp(r'[0-9]'));

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 40),
          children: [
            // Role the user is registering as — clear at a glance.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: _role == UserRole.vendor
                        ? HugeIcons.strokeRoundedStore02
                        : HugeIcons.strokeRoundedRestaurant02,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Register as ${_role.label}',
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Join others reducing food waste today.',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _field(_name, 'Full name', HugeIcons.strokeRoundedUserCircle,
                textInputAction: TextInputAction.next),
            const SizedBox(height: AppSpacing.lg),
            _field(_phone, 'Phone number *', HugeIcons.strokeRoundedCall,
                keyboard: TextInputType.phone,
                textInputAction: TextInputAction.next),
            const SizedBox(height: AppSpacing.lg),
            _field(_email, 'Email address', HugeIcons.strokeRoundedMail01,
                keyboard: TextInputType.emailAddress,
                textInputAction: TextInputAction.next),
            const SizedBox(height: AppSpacing.lg),
            _field(
              _password,
              'Password',
              HugeIcons.strokeRoundedLockKey,
              obscure: _obscure,
              onSubmit: (_) => _register(),
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: HugeIcon(
                  icon: _obscure
                      ? HugeIcons.strokeRoundedView
                      : HugeIcons.strokeRoundedViewOff,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Always-visible password rules so nobody guesses (and gets rejected).
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HugeIcon(
                  icon: pwValid
                      ? HugeIcons.strokeRoundedCheckmarkCircle02
                      : HugeIcons.strokeRoundedInformationCircle,
                  size: 15,
                  color: pwValid ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'At least 8 characters, with a lowercase letter and a number.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: pwValid
                          ? AppColors.primaryDark
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HugeIcon(
                        icon: HugeIcons.strokeRoundedAlert02,
                        size: 16,
                        color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
    dynamic icon, {
    bool obscure = false,
    TextInputType? keyboard,
    TextInputAction? textInputAction,
    Widget? suffix,
    ValueChanged<String>? onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: keyboard,
          textInputAction: textInputAction,
          onSubmitted: onSubmit,
          // Clear the error banner as soon as the user starts fixing things.
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
            if (label == 'Password') setState(() {});
          },
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: HugeIcon(icon: icon, size: 20, color: AppColors.textMuted),
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
