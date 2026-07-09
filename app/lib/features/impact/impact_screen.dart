import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/motion.dart';
import '../buyer/application/marketplace_providers.dart';
import '../buyer/domain/order.dart';

/// Impact constants shared with the backend engine: 2.5 meals and 2.5 kg of
/// avoided CO₂ per kg of produce rescued.
const double _mealsPerKg = 2.5;
const double _co2PerKg = 2.5;

/// The current buyer's own impact, derived from their real completed orders —
/// no network-wide or fabricated numbers.
class _MyImpact {
  const _MyImpact(this.orders, this.kg, this.meals, this.co2, this.saved);
  final int orders;
  final double kg;
  final double meals;
  final double co2;
  final double saved;
  bool get isEmpty => orders == 0;

  static _MyImpact from(List<Order> all) {
    final done = all.where((o) => o.status == OrderStatus.completed).toList();
    final kg = done.fold<double>(0, (s, o) => s + o.quantityKg);
    final saved = done.fold<double>(0, (s, o) => s + o.saved);
    return _MyImpact(
        done.length, kg, kg * _mealsPerKg, kg * _co2PerKg, saved);
  }
}

const _co2Accent = (
  fg: Color(0xFF0F766E),
  bg: Color(0xFFD5F5F1),
  border: Color(0xFFB4EBE4),
);

/// Buyer-facing "Impact" tab — the buyer's own contribution only, styled like
/// the seller dashboard's stats strip: a standard green header + a floating
/// white stats card with real numbers from the buyer's completed orders.
class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final m = _MyImpact.from(ordersAsync.valueOrNull ?? const []);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ordersProvider.future),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context, m),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, 90),
              child: ordersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Center(child: Text('Could not load orders: $e')),
                data: (_) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.isEmpty)
                      _emptyState()
                    else ...[
                      FadeSlideIn(child: _co2Card(m)),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _rescueCta(context),
                    const SizedBox(height: AppSpacing.md),
                    _footerNote(m),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Standard green header (flat, matches every other screen) + a floating
  // white stats strip in the seller-dashboard style.
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, _MyImpact m) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: AppSpacing.lg,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Impact',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Real numbers from the orders you\'ve completed',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatsStrip(m: m),
        ],
      ),
    );
  }

  Widget _co2Card(_MyImpact m) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _co2Accent.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _co2Accent.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
                icon: HugeIcons.strokeRoundedLeaf02,
                color: _co2Accent.fg,
                size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatCount(m.co2)} kg CO₂ avoided',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _co2Accent.fg),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Estimated from the produce you rescued instead of letting it waste.',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingBasket01,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No completed orders yet',
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Rescue your first surplus order and your impact will start '
            'adding up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _rescueCta(BuildContext context) {
    return Pressable(
      onTap: () => context.push('/rescues'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDeliveryTruck02,
                  color: AppColors.primaryDark,
                  size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore the rescue network',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  SizedBox(height: 2),
                  Text(
                      'See surplus routed to community kitchens & NGOs, live.',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textMuted,
                size: 18),
          ],
        ),
      ),
    );
  }

  Widget _footerNote(_MyImpact m) {
    return Center(
      child: Text(
        m.isEmpty
            ? 'Your impact grows with every order you complete.'
            : 'From ${m.orders} completed order${m.orders == 1 ? '' : 's'} — thank you for reducing food waste.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
      ),
    );
  }
}

/// A floating white stats strip inside the header, matching the seller
/// dashboard's `_StatsStrip` pattern exactly: three headline numbers with
/// hairline dividers.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.m});
  final _MyImpact m;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _Stat(
            icon: HugeIcons.strokeRoundedRecycle01,
            iconColor: AppColors.primary,
            value: formatKg(m.kg),
            label: 'Rescued',
          ),
          const _StatDivider(),
          _Stat(
            icon: HugeIcons.strokeRoundedUserMultiple,
            iconColor: const Color(0xFFB45309),
            value: formatCount(m.meals),
            label: 'Meals',
          ),
          const _StatDivider(),
          _Stat(
            icon: HugeIcons.strokeRoundedMoneyBag02,
            iconColor: const Color(0xFF6D28D9),
            value: formatMoney(m.saved),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final dynamic icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          HugeIcon(icon: icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: AppColors.border,
    );
  }
}
