import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';

/// Refer & earn — a stable per-user code plus a shareable message. Credits on
/// the referred user's first order are future scope (needs a backend endpoint);
/// the code + share flow are live.
class ReferScreen extends ConsumerWidget {
  const ReferScreen({super.key});

  static const _steps = <({IconData icon, String title, String sub})>[
    (
      icon: Icons.ios_share_rounded,
      title: 'Share your code',
      sub: 'Send it to a hotel or vendor you know'
    ),
    (
      icon: Icons.person_add_alt_1_outlined,
      title: 'They join Revivo',
      sub: 'and enter your code when signing up'
    ),
    (
      icon: Icons.savings_outlined,
      title: 'You both earn ₹50 credits',
      sub: 'when they complete their first rescue'
    ),
  ];

  String _code(WidgetRef ref) {
    final session = ref.read(sessionProvider);
    final seed = session?.userId ?? session?.name ?? 'REVIVO';
    final alnum = seed.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final tail = alnum.length >= 5
        ? alnum.substring(alnum.length - 5)
        : alnum.padLeft(5, 'X');
    return 'REV-$tail';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = _code(ref);
    final shareText =
        'Rescue surplus veggies at a discount on Revivo and cut food waste. '
        'Use my code $code when you sign up. 🌱';

    return Scaffold(
      appBar: AppBar(title: const Text('Refer & earn')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.card_giftcard_rounded,
                      color: Colors.white, size: 34),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Give ₹50, get ₹50',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.lg),
                  DottedCode(code: code),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                              const SnackBar(content: Text('Code copied')));
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy code'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Share',
                    icon: Icons.ios_share_rounded,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                              content:
                                  Text('Invite copied — share it anywhere')));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'How it works'),
            const SizedBox(height: AppSpacing.sm),
            for (final s in _steps) ...[
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(s.icon,
                          size: 20, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(s.sub,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

/// The referral code shown as a dashed "coupon" pill.
class DottedCode extends StatelessWidget {
  const DottedCode({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
