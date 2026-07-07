import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_role.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/format.dart';
import '../../core/widgets/app_card.dart';
import '../buyer/application/marketplace_providers.dart';
import '../buyer/application/wallet_providers.dart';
import 'application/profile_providers.dart';
import 'badges.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final details = ref.watch(profileDetailsProvider);
    final role = session?.role ?? UserRole.vendor;
    final name = session?.name ?? details.name;
    final email = session?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const SizedBox(height: AppSpacing.sm),
            _identity(name, email, role),
            const SizedBox(height: AppSpacing.lg),
            _contactCard(context, details),
            if (role == UserRole.buyer) ...[
              const SizedBox(height: AppSpacing.lg),
              _walletCard(ref.watch(walletProvider)),
            ],
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
            if (role == UserRole.buyer) ...[
              const SizedBox(height: AppSpacing.xl),
              _badges(ref),
            ],
            const SizedBox(height: AppSpacing.xl),
            _menu(context),
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

  /// Quick glance at the number + address, tappable through to full editing.
  Widget _contactCard(BuildContext context, ProfileDetails details) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/account'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _contactRow(Icons.call_outlined, details.phone),
                    const SizedBox(height: 8),
                    _contactRow(Icons.place_outlined, details.fullAddress),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _badges(WidgetRef ref) {
    final orders = ref.watch(ordersProvider).valueOrNull ?? const [];
    final saved = orders.fold<double>(0, (s, o) => s + o.saved);
    final kg = orders.fold<double>(0, (s, o) => s + o.quantityKg);
    final badges = buyerBadges(orders: orders.length, saved: saved, kg: kg);
    final earned = badges.where((b) => b.earned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Milestones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$earned / ${badges.length}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final b in badges) _badgeChip(b)],
        ),
      ],
    );
  }

  Widget _badgeChip(MilestoneBadge b) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: b.earned ? AppColors.primarySurface : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: b.earned ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(b.icon,
              size: 22,
              color: b.earned ? AppColors.primary : AppColors.textMuted),
          const SizedBox(height: 6),
          Text(b.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: b.earned ? AppColors.textPrimary : AppColors.textMuted,
              )),
          const SizedBox(height: 1),
          Text(b.sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _walletCard(int balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: Colors.white, size: 26),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revivo credits',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(formatMoney(balance.toDouble()),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text('1 credit / ₹10 saved',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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

  Widget _menu(BuildContext context) {
    final items = <(IconData, String, VoidCallback?)>[
      (Icons.person_outline, 'Account details', () => context.push('/account')),
      (
        Icons.notifications_none_rounded,
        'Notifications',
        () => context.push('/notifications')
      ),
      (
        Icons.card_giftcard_outlined,
        'Refer & earn',
        () => context.push('/refer')
      ),
      (Icons.help_outline, 'Help & safety', () => context.push('/help')),
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
              onTap: items[i].$3,
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }
}
