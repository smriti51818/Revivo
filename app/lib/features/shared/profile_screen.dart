import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/user_role.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import 'application/profile_providers.dart';
import 'application/profile_stats_providers.dart';

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
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(profileStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _Header(name: name, email: email, role: role),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  children: [
                    _StatsRow(role: role, stats: stats),
                    const SizedBox(height: AppSpacing.md),
                    _MenuCard(role: role),
                    const SizedBox(height: AppSpacing.md),
                    _InsightsBanner(role: role),
                    const SizedBox(height: AppSpacing.md),
                    _LogoutButton(ref: ref),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Revivo · Time-Aware Food Recovery',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header with dark green banner + identity card ──────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.email, required this.role});
  final String name;
  final String email;
  final UserRole role;

  String get _roleLabel => switch (role) {
    UserRole.vendor => 'Surplus Vendor',
    UserRole.buyer => 'Hotel Kitchen',
  };

  String get _verifiedLabel => switch (role) {
    UserRole.vendor => 'Verified Seller',
    UserRole.buyer => 'Verified Buyer',
  };

  dynamic get _roleIcon => switch (role) {
    UserRole.vendor => HugeIcons.strokeRoundedStore02,
    UserRole.buyer => HugeIcons.strokeRoundedRestaurant02,
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dark green background band
        Container(
          height: 160,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Identity card floating over the band
        Positioned(
          top: 108,
          left: AppSpacing.screen,
          right: AppSpacing.screen,
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    // Role icon badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: HugeIcon(
                          icon: _roleIcon,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name.isNotEmpty ? name : 'User',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon:
                                      HugeIcons.strokeRoundedCheckmarkCircle02,
                                  size: 11,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _verifiedLabel,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _roleLabel,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Spacer so Stack has room for the card
        const SizedBox(height: 210, width: double.infinity),
      ],
    );
  }

}

// ── Stats row — 3 tiles, content varies by role ────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.role, required this.stats});
  final UserRole role;
  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = _tilesFor(role, stats);
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          Expanded(child: tiles[i]),
          if (i < tiles.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  List<_StatTile> _tilesFor(UserRole role, ProfileStats s) => switch (role) {
    UserRole.vendor => [
      _StatTile(
        icon: HugeIcons.strokeRoundedShoppingBag01,
        iconBg: AppColors.primarySurface,
        iconColor: AppColors.primaryDark,
        label: 'Orders',
        value: '${s.vendorOrders}',
      ),
      _StatTile(
        icon: HugeIcons.strokeRoundedPackageOpen,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF2F80ED),
        label: 'Qty Sold',
        value: formatKg(s.vendorSoldKg),
      ),
      _StatTile(
        icon: HugeIcons.strokeRoundedMoney01,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFF2994A),
        label: 'Earnings',
        value: formatMoney(s.vendorRevenue),
      ),
    ],
    UserRole.buyer => [
      _StatTile(
        icon: HugeIcons.strokeRoundedShoppingBag01,
        iconBg: AppColors.primarySurface,
        iconColor: AppColors.primaryDark,
        label: 'Orders',
        value: '${s.buyerOrders}',
      ),
      _StatTile(
        icon: HugeIcons.strokeRoundedMoney01,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFF2994A),
        label: 'Saved',
        value: formatMoney(s.buyerSaved),
      ),
      _StatTile(
        icon: HugeIcons.strokeRoundedLeaf02,
        iconBg: AppColors.primarySurface,
        iconColor: AppColors.primaryDark,
        label: 'Rescued',
        value: formatKg(s.buyerKg),
      ),
    ],
  };
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final dynamic icon;
  final Color iconBg, iconColor;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: HugeIcon(icon: icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu card — role-aware items ───────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.role});
  final UserRole role;

  List<({dynamic icon, String title, String subtitle, String? route})>
  get _items => switch (role) {
    UserRole.vendor => [
      (
        icon: HugeIcons.strokeRoundedUserCircle,
        title: 'Account Details',
        subtitle: 'Edit name, phone, address',
        route: '/account',
      ),
      (
        icon: HugeIcons.strokeRoundedStar,
        title: 'Reviews',
        subtitle: 'See what buyers say about you',
        route: '/seller/profile/reviews',
      ),
      (
        icon: HugeIcons.strokeRoundedNotification01,
        title: 'Notifications',
        subtitle: 'Manage alerts and reminders',
        route: '/notifications',
      ),
      (
        icon: HugeIcons.strokeRoundedHelpCircle,
        title: 'Help & Safety',
        subtitle: 'FAQs and support',
        route: '/help',
      ),
    ],
    UserRole.buyer => [
      (
        icon: HugeIcons.strokeRoundedUserCircle,
        title: 'Account Details',
        subtitle: 'Edit name, phone, address',
        route: '/account',
      ),
      (
        icon: HugeIcons.strokeRoundedReceiptText,
        title: 'My Orders',
        subtitle: 'Track and manage your orders',
        route: '/buyer/orders',
      ),
      (
        icon: HugeIcons.strokeRoundedGift,
        title: 'Refer & earn',
        subtitle: 'Give ₹50, get ₹50 in credits',
        route: '/refer',
      ),
      (
        icon: HugeIcons.strokeRoundedNotification01,
        title: 'Notifications',
        subtitle: 'Manage alerts and reminders',
        route: '/notifications',
      ),
      (
        icon: HugeIcons.strokeRoundedHelpCircle,
        title: 'Help & Safety',
        subtitle: 'FAQs and support',
        route: '/help',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: items[i].icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                items[i].title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                items[i].subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: AppColors.textMuted,
              ),
              onTap: () {
                final r = items[i].route;
                if (r != null) context.push(r);
              },
            ),
            if (i < items.length - 1)
              const Divider(height: 1, indent: 64, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

// ── Insights / impact banner — role-aware ─────────────────────────────────

class _InsightsBanner extends StatelessWidget {
  const _InsightsBanner({required this.role});
  final UserRole role;

  ({String title, String sub, String btnLabel, String? route}) get _copy =>
      switch (role) {
        UserRole.vendor => (
          title: 'Grow your impact with Revivo',
          sub: 'Keep listing surplus to reduce waste and earn more revenue.',
          btnLabel: 'View insights',
          route: '/seller/insights',
        ),
        UserRole.buyer => (
          title: 'Your rescue impact',
          sub: 'Every order saves food from going to waste. Track your story.',
          btnLabel: 'View impact',
          route: '/buyer/impact',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final c = _copy;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedLeaf02,
              size: 22,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.sub,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: c.route != null ? () => context.push(c.route!) : null,
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              c.btnLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logout ────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.dangerSurface,
            shape: BoxShape.circle,
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedLogout01,
            size: 18,
            color: AppColors.danger,
          ),
        ),
        title: const Text(
          'Sign out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: const Text(
          'You can log back in anytime',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          size: 18,
          color: AppColors.textMuted,
        ),
        onTap: () {
          ref.read(sessionProvider.notifier).signOut();
          context.go('/role');
        },
      ),
    );
  }
}
