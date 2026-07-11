import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/motion.dart';
import '../buyer/application/marketplace_providers.dart';
import '../buyer/domain/order.dart';

const double _mealsPerKg = 2.5;
const double _co2PerKg = 2.5;

class _MyImpact {
  const _MyImpact(this.orders, this.kg, this.meals, this.co2, this.saved,
      this.allOrders);
  final int orders;
  final double kg;
  final double meals;
  final double co2;
  final double saved;
  final List<Order> allOrders;
  bool get isEmpty => orders == 0;

  static _MyImpact from(List<Order> all) {
    final done = all.where((o) => o.status == OrderStatus.completed).toList();
    final kg = done.fold<double>(0, (s, o) => s + o.quantityKg);
    final saved = done.fold<double>(0, (s, o) => s + o.saved);
    return _MyImpact(
        done.length, kg, kg * _mealsPerKg, kg * _co2PerKg, saved, all);
  }
}

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
                error: (e, _) =>
                    Center(child: Text('Could not load orders: $e')),
                data: (_) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.isEmpty) ...[
                      _emptyState(),
                    ] else ...[
                      FadeSlideIn(child: _co2Card(m)),
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(child: _rescueChart(m)),
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(child: _orderBreakdown(m)),
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(child: _topVegetables(m)),
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
    const accent = (
      fg: Color(0xFF0F766E),
      bg: Color(0xFFD5F5F1),
      border: Color(0xFFB4EBE4),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.border),
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
                color: accent.fg,
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
                      color: accent.fg),
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

  Widget _rescueChart(_MyImpact m) {
    final completed =
        m.allOrders.where((o) => o.status == OrderStatus.completed).toList();
    if (completed.isEmpty) return const SizedBox.shrink();

    completed.sort((a, b) => a.placedAt.compareTo(b.placedAt));

    final now = DateTime.now();
    final wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final labels = <String>[];
    final values = <double>[];

    for (var i = 6; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      labels.add(wd[day.weekday - 1]);
      final dayKg = completed
          .where((o) =>
              o.placedAt.year == day.year &&
              o.placedAt.month == day.month &&
              o.placedAt.day == day.day)
          .fold<double>(0, (s, o) => s + o.quantityKg);
      values.add(dayKg);
    }

    final maxVal = values.reduce(max);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedChartLineData01,
                  size: 18,
                  color: AppColors.primary),
              SizedBox(width: 8),
              Text('Rescue Activity (This Week)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal > 0 ? maxVal * 1.3 : 10,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(6),
                    tooltipMargin: 6,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)} kg',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(labels[idx],
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: values[i] > 0
                              ? AppColors.primary
                              : AppColors.border,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderBreakdown(_MyImpact m) {
    final active = m.allOrders
        .where((o) => o.status != OrderStatus.completed)
        .length;
    final completed = m.orders;
    final totalSpent = m.allOrders
        .where((o) => o.status == OrderStatus.completed)
        .fold<double>(0, (s, o) => s + o.total);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedInvoice01,
                  size: 18,
                  color: AppColors.primary),
              SizedBox(width: 8),
              Text('Order Summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _miniStat(
                      '${m.allOrders.length}', 'Total Orders',
                      HugeIcons.strokeRoundedShoppingBag01,
                      AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: _miniStat(
                      '$active', 'Active',
                      HugeIcons.strokeRoundedClock01,
                      const Color(0xFFF2994A))),
              const SizedBox(width: 10),
              Expanded(
                  child: _miniStat(
                      '$completed', 'Completed',
                      HugeIcons.strokeRoundedCheckmarkCircle02,
                      const Color(0xFF27AE60))),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Spent',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  Text(formatMoney(totalSpent),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Saved',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  Text(formatMoney(m.saved),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      String value, String label, dynamic icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _topVegetables(_MyImpact m) {
    final completed =
        m.allOrders.where((o) => o.status == OrderStatus.completed).toList();
    if (completed.isEmpty) return const SizedBox.shrink();

    final vegMap = <String, double>{};
    for (final o in completed) {
      vegMap[o.vegetable] = (vegMap[o.vegetable] ?? 0) + o.quantityKg;
    }
    final sorted = vegMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxKg = top.first.value;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedLeaf02,
                  size: 18,
                  color: AppColors.primary),
              SizedBox(width: 8),
              Text('Top Rescued Produce',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _produceRow(top[i].key, top[i].value, maxKg),
          ],
        ],
      ),
    );
  }

  Widget _produceRow(String name, double kg, double maxKg) {
    final pct = maxKg > 0 ? kg / maxKg : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            Text('${kg.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
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
