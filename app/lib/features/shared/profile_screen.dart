import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_role.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final role = session?.role ?? UserRole.vendor;
    final name = session?.name ?? 'Guest';
    final email = session?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const SizedBox(height: AppSpacing.sm),
            _identity(name, email, role),
            const SizedBox(height: AppSpacing.lg),
            _trustCard(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                for (final stat in _statsFor(role)) ...[
                  Expanded(child: _statTile(stat.$1, stat.$2)),
                  if (stat != _statsFor(role).last)
                    const SizedBox(width: AppSpacing.md),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _menu(),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(sessionProvider.notifier).signOut();
                context.go('/role');
              },
              icon: const Icon(Icons.logout, size: 18, color: AppColors.danger),
              label: const Text('Sign out',
                  style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Center(
              child: Text(
                'Revivo · Time-Aware Food Recovery',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity(String name, String email, UserRole role) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                role.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trustCard() {
    const verified = 'Verified partner';
    return AppCard(
      color: AppColors.primarySurface,
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.primary, size: 26),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Identity confirmed · builds trust across the network',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
              SizedBox(width: 2),
              Text('4.8',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  List<(String, String)> _statsFor(UserRole role) => switch (role) {
        UserRole.vendor => [('Listings', '12'), ('Saved from waste', '340 kg')],
        UserRole.buyer => [('Orders', '28'), ('You saved', '₹6,200')],
        UserRole.cook => [('Meals served', '~1,200'), ('Rescues', '48')],
      };

  Widget _statTile(String label, String value) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu() {
    const items = [
      (Icons.person_outline, 'Account details'),
      (Icons.notifications_none_rounded, 'Notifications'),
      (Icons.help_outline, 'Help & support'),
      (Icons.info_outline, 'About Revivo'),
    ];
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              leading: Icon(items[i].$1, color: AppColors.textSecondary),
              title: Text(items[i].$2,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textMuted),
              onTap: () {},
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }
}
