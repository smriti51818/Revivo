import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_role.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/format.dart';
import '../../core/widgets/app_card.dart';
import 'application/profile_providers.dart';
import 'application/profile_stats_providers.dart';
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
    final stats =
        ref.watch(profileStatsProvider).valueOrNull ?? ProfileStats.empty;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(profileStatsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              const SizedBox(height: AppSpacing.sm),
              _identity(name, email, role),
              const SizedBox(height: AppSpacing.lg),
              _contactCard(context, details),
              const SizedBox(height: AppSpacing.lg),
              _ledgerCard(role, stats),
              const SizedBox(height: AppSpacing.lg),
              _trustCard(role, stats),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  for (final stat in _statsFor(role, stats)) ...[
                    Expanded(child: _statTile(stat.$1, stat.$2)),
                    if (stat != _statsFor(role, stats).last)
                      const SizedBox(width: AppSpacing.md),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _badges(role, stats),
              const SizedBox(height: AppSpacing.xl),
              _menu(context),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(sessionProvider.notifier).signOut();
                  context.go('/role');
                },
                icon:
                    const Icon(Icons.logout, size: 18, color: AppColors.danger),
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

  Widget _badges(UserRole role, ProfileStats s) {
    final badges = switch (role) {
      UserRole.vendor => sellerBadges(
          orders: s.vendorOrders,
          kg: s.vendorSoldKg,
          revenue: s.vendorRevenue,
          trusted: s.vendorTrusted,
        ),
      UserRole.cook => cookBadges(
          rescues: s.cookRescues,
          meals: s.cookMeals,
          kg: s.cookKg,
        ),
      UserRole.buyer => buyerBadges(
          orders: s.buyerOrders,
          saved: s.buyerSaved,
          kg: s.buyerKg,
        ),
    };
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

  /// A role-appropriate value ledger — the buyer's redeemable credits, the
  /// seller's recovered revenue, or the cook's meals served. All real numbers.
  Widget _ledgerCard(UserRole role, ProfileStats s) {
    final (icon, label, value, tag) = switch (role) {
      UserRole.buyer => (
          Icons.account_balance_wallet_outlined,
          'Revivo credits',
          formatMoney(s.walletCredits.toDouble()),
          '1 credit / ₹10 saved',
        ),
      UserRole.vendor => (
          Icons.payments_outlined,
          'Recovered from waste',
          formatMoney(s.vendorRevenue),
          '${formatKg(s.vendorSoldKg)} sold',
        ),
      UserRole.cook => (
          Icons.restaurant_rounded,
          'Meals served',
          '~${formatCount(s.cookMeals)}',
          '${s.cookRescues} rescues',
        ),
    };
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
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(tag,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Trust card. Sellers show their real earned rating + Trusted badge; other
  /// roles show identity-verified partner status.
  Widget _trustCard(UserRole role, ProfileStats s) {
    final isSeller = role == UserRole.vendor;
    final hasRating = isSeller && s.vendorRatingCount > 0;
    final title = isSeller && s.vendorTrusted
        ? 'Trusted vendor'
        : 'Verified partner';
    final subtitle = hasRating
        ? '${s.vendorRatingCount} ratings · builds trust across the network'
        : 'Identity confirmed · builds trust across the network';
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (hasRating)
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                const SizedBox(width: 2),
                Text(s.vendorRating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
        ],
      ),
    );
  }

  List<(String, String)> _statsFor(UserRole role, ProfileStats s) =>
      switch (role) {
        UserRole.vendor => [
            ('Orders', '${s.vendorOrders}'),
            ('Saved from waste', formatKg(s.vendorSoldKg)),
          ],
        UserRole.buyer => [
            ('Orders', '${s.buyerOrders}'),
            ('You saved', formatMoney(s.buyerSaved)),
          ],
        UserRole.cook => [
            ('Meals served', '~${formatCount(s.cookMeals)}'),
            ('Rescues', '${s.cookRescues}'),
          ],
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
