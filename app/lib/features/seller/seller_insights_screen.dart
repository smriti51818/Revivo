import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../buyer/domain/order.dart';
import 'application/insights_providers.dart';
import 'application/listings_providers.dart';
import 'application/vendor_orders_providers.dart';
import 'domain/listing.dart';
import 'domain/seller_insights.dart';
import 'domain/waste_risk.dart';

const _vegEmoji = <String, String>{
  'Tomato': '🍅', 'Potato': '🥔', 'Onion': '🧅', 'Spinach': '🥬',
  'Coriander': '🌿', 'Carrot': '🥕', 'Bell Pepper': '🫑', 'Cabbage': '🥬',
  'Cauliflower': '🥦', 'Brinjal': '🍆', 'Okra': '🌱', 'Green Chilli': '🌶️',
  'Cucumber': '🥒', 'Beans': '🫘', 'Beetroot': '🫚', 'Pumpkin': '🎃',
  'Drumstick': '🌿', 'Curry Leaves': '🌿', 'Mint': '🌿', 'Radish': '🌱',
};

class SellerInsightsScreen extends ConsumerStatefulWidget {
  const SellerInsightsScreen({super.key});

  @override
  ConsumerState<SellerInsightsScreen> createState() =>
      _SellerInsightsScreenState();
}

class _SellerInsightsScreenState extends ConsumerState<SellerInsightsScreen> {
  String _period = 'week';

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(sellerInsightsProvider(_period));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: insightsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Could not load insights: $e')),
              data: (insights) => ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildPeriodFilter(),
                  const SizedBox(height: 12),
                  _buildTopRow(insights),
                  const SizedBox(height: 16),
                  _buildWasteRisk(),
                  _buildEarningsOverview(_earningsFor(insights)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildListingsPerformance(insights)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildTopPerformingProduce(insights)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildImpact(insights.impact),
                  const SizedBox(height: 16),
                  _buildRecentInsights(insights),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insights',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Track your impact, performance and growth',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    const options = {
      'week': 'This Week',
      'month': 'This Month',
      'year': 'This Year',
    };
    return Row(
      children: options.entries.map((e) {
        final active = _period == e.key;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _period = e.key),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopRow(SellerInsightsData insights) {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                HugeIcons.strokeRoundedShoppingBag01,
                const Color(0xFF27AE60),
                'Earnings',
                '₹${insights.revenue.toInt()}',
                '${insights.orders} orders')),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard(
                HugeIcons.strokeRoundedTag01,
                const Color(0xFF27AE60),
                'Listings',
                '${insights.activeListings}',
                'Active')),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard(
                HugeIcons.strokeRoundedShoppingBag02,
                const Color(0xFF2D9CDB),
                'Qty Sold',
                '${insights.soldKg.toInt()} kg',
                'Sold')),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard(
                HugeIcons.strokeRoundedRestaurant01,
                const Color(0xFFF2994A),
                'Meals',
                '${insights.impact.meals}',
                'Saved')),
      ],
    );
  }

  /// Forward-looking waste-risk projection over the seller's live listings —
  /// how much stock will hit the RESCUE band within a day, so they can discount
  /// or route it before it's waste. Hidden when there's nothing at risk.
  Widget _buildWasteRisk() {
    final listings = ref.watch(listingsProvider).valueOrNull ?? const <Listing>[];
    final risk = computeWasteRisk(listings);
    if (risk.isEmpty) return const SizedBox.shrink();

    const danger = Color(0xFFF23E3E);
    const warn = Color(0xFFF2994A);
    final tone = risk.rescueNowCount > 0 ? danger : warn;
    final headline = risk.rescueNowCount > 0
        ? '${risk.rescueNowCount} listing${risk.rescueNowCount == 1 ? '' : 's'} in Rescue band now'
        : '${risk.count} listing${risk.count == 1 ? '' : 's'} nearing Rescue';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tone.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: HugeIcon(
                        icon: HugeIcons.strokeRoundedAlert02,
                        color: tone,
                        size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Waste risk — next 24h',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        Text(headline,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: tone)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${formatKg(risk.atRiskKg)} at risk',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary)),
                      Text('${formatMoney(risk.atRiskValue)} value',
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final it in risk.items.take(3)) ...[
                _wasteRow(it, tone),
                const SizedBox(height: 7),
              ],
              const SizedBox(height: 2),
              Text(
                risk.rescueNowCount > 0
                    ? 'Discount now or route to a rescue NGO before these expire.'
                    : 'Prices auto-drop as they age — or route to a rescue NGO to avoid waste.',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => context.push('/rescues'),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                        icon: HugeIcons.strokeRoundedDeliveryTruck02,
                        size: 15,
                        color: tone),
                    const SizedBox(width: 6),
                    Text('Open the rescue network',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: tone)),
                    const SizedBox(width: 2),
                    HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 14,
                        color: tone),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _wasteRow(WasteRiskItem it, Color tone) {
    final emoji = _vegEmoji[it.listing.vegetable] ?? '🥗';
    final when = it.alreadyRescue
        ? 'Rescue now'
        : it.hoursToRescue < 1
            ? '< 1h'
            : 'in ${it.hoursToRescue.round()}h';
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(
          child: Text('${it.listing.vegetable} · ${formatKg(it.kg)}',
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(when,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w800, color: tone)),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      dynamic icon, Color iconColor, String title, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(icon: icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(sub,
                style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// The earnings series to chart. Prefers the server-aggregated series; if a
  /// stale deploy omits it, buckets the seller's *real* orders locally with the
  /// same day-window logic so the chart shows genuine revenue, never a blank.
  EarningsSeries _earningsFor(SellerInsightsData insights) {
    if (insights.earnings.hasData) return insights.earnings;
    final orders = ref.watch(vendorOrdersProvider).valueOrNull ?? const <Order>[];
    return _earningsFromOrders(orders, _period);
  }

  EarningsSeries _earningsFromOrders(List<Order> orders, String period) {
    // Bucket by day for week/today, by week for month, by month for year.
    final now = DateTime.now();
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    if (period == 'year') {
      // 12 monthly buckets ending at current month.
      final labels = <String>[];
      final values = <double>[];
      for (var i = 11; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        labels.add(months[m.month - 1]);
        final total = orders
            .where((o) => o.placedAt.year == m.year && o.placedAt.month == m.month)
            .fold<double>(0, (s, o) => s + o.total);
        values.add(double.parse(total.toStringAsFixed(0)));
      }
      return EarningsSeries(labels: labels, values: values);
    }

    final int days = switch (period) {
      'today' => 1,
      'month' => 30,
      _ => 7,
    };
    if (days <= 7) {
      final labels = <String>[];
      final values = <double>[];
      for (var i = days - 1; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        labels.add(days == 1 ? 'Today' : wd[day.weekday - 1]);
        final total = orders
            .where((o) =>
                o.placedAt.year == day.year &&
                o.placedAt.month == day.month &&
                o.placedAt.day == day.day)
            .fold<double>(0, (s, o) => s + o.total);
        values.add(double.parse(total.toStringAsFixed(0)));
      }
      return EarningsSeries(labels: labels, values: values);
    }
    // Month view: 4 weekly buckets.
    final labels = <String>[];
    final values = <double>[];
    for (var w = 3; w >= 0; w--) {
      final end = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: w * 7));
      final start = end.subtract(const Duration(days: 6));
      labels.add('W${4 - w}');
      final total = orders
          .where((o) =>
              !o.placedAt.isBefore(start) &&
              !o.placedAt.isAfter(end.add(const Duration(days: 1))))
          .fold<double>(0, (s, o) => s + o.total);
      values.add(double.parse(total.toStringAsFixed(0)));
    }
    return EarningsSeries(labels: labels, values: values);
  }

  Widget _buildEarningsOverview(EarningsSeries earnings) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Earnings Overview',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: earnings.hasData
                ? LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '₹${spot.y.toInt()}',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (earnings.values.reduce(max) <= 0 ? 500 : earnings.values.reduce(max)) / 4,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(color: AppColors.border, strokeWidth: 0.5);
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < earnings.labels.length) {
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(earnings.labels[idx], style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (earnings.values.reduce(max) <= 0 ? 500 : earnings.values.reduce(max)) / 4,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max) return const SizedBox.shrink();
                              final label = value >= 1000 ? '₹${(value / 1000).toStringAsFixed(1)}k' : '₹${value.toInt()}';
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (earnings.labels.length - 1).toDouble(),
                      minY: 0,
                      maxY: (earnings.values.reduce(max) <= 0 ? 500 : earnings.values.reduce(max)) * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            earnings.values.length,
                            (index) => FlSpot(index.toDouble(), earnings.values[index]),
                          ),
                          isCurved: false,
                          color: const Color(0xFF27AE60),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Text('No earnings in this period yet',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsPerformance(SellerInsightsData insights) {
    final total = insights.good + insights.useSoon + insights.rescue;
    final goodPct = total > 0 ? insights.good / total * 100 : 0.0;
    final soonPct = total > 0 ? insights.useSoon / total * 100 : 0.0;
    final rescuePct = total > 0 ? insights.rescue / total * 100 : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Listings Performance',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Column(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CustomPaint(
                  painter: DonutChartPainter(
                      goodPct: goodPct,
                      soonPct: soonPct,
                      rescuePct: rescuePct),
                  // Removed center text as requested
                ),
              ),
              const SizedBox(height: 24),
              _buildLegendItem(const Color(0xFF27AE60), 'Good',
                  '${insights.good}', '(${goodPct.toInt()}%)'),
              const SizedBox(height: 8),
              _buildLegendItem(const Color(0xFFF2994A), 'Use Soon',
                  '${insights.useSoon}', '(${soonPct.toInt()}%)'),
              const SizedBox(height: 8),
              _buildLegendItem(const Color(0xFFD32F2F), 'Rescue',
                  '${insights.rescue}', '(${rescuePct.toInt()}%)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      Color color, String label, String value, String pct) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600))),
        Text(value,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textPrimary)),
        const SizedBox(width: 4),
        Text(pct,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTopPerformingProduce(SellerInsightsData insights) {
    final movers = insights.movers;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Performing Produce',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (movers.isEmpty)
            const Text('No sales in this period yet',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary))
          else
            for (var i = 0; i < movers.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildProduceRow(movers[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildProduceRow(MoverRow mover) {
    final key = _vegEmoji.keys.firstWhere(
        (k) => k.toLowerCase() == mover.vegetable.toLowerCase().trim(),
        orElse: () => '');
    final emoji = key.isNotEmpty ? _vegEmoji[key]! : '🥬';
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: const Color(0xFFF4F7F5),
              borderRadius: BorderRadius.circular(6)),
          child: Center(
              child: Text(emoji,
                  style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mover.vegetable,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${mover.kg.toInt()} kg sold',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text('₹${mover.revenue.toInt()}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF27AE60))),
      ],
    );
  }

  Widget _buildImpact(SellerImpact impact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Impact You're Creating",
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                  child: _buildImpactCol(
                      HugeIcons.strokeRoundedLeaf02,
                      const Color(0xFF27AE60),
                      '${impact.foodKeptKg.toInt()} kg',
                      'Food kept from waste')),
              Container(width: 1, height: 60, color: AppColors.border),
              Expanded(
                  child: _buildImpactCol(
                      HugeIcons.strokeRoundedUserMultiple,
                      const Color(0xFF2D9CDB),
                      '${impact.meals}',
                      'Meals saved')),
              Container(width: 1, height: 60, color: AppColors.border),
              Expanded(
                  child: _buildImpactCol(
                      HugeIcons.strokeRoundedMoney01,
                      const Color(0xFFF2994A),
                      '₹${impact.buyerSavings.toInt()}',
                      'Buyer savings')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactCol(
      dynamic icon, Color color, String value, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: HugeIcon(icon: icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2),
      ],
    );
  }

  Widget _buildRecentInsights(SellerInsightsData insights) {
    final recs = insights.recommendations;
    final aiPowered = insights.aiPowered;

    final icons = [
      HugeIcons.strokeRoundedChartLineData01,
      HugeIcons.strokeRoundedTime01,
      HugeIcons.strokeRoundedTag01,
    ];
    final colors = [
      const Color(0xFF27AE60),
      const Color(0xFF7CB342),
      const Color(0xFFF2994A),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Recent Insights',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: aiPowered
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                      icon: HugeIcons.strokeRoundedSparkles,
                      size: 11,
                      color: aiPowered
                          ? const Color(0xFF27AE60)
                          : AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(aiPowered ? 'AI generated' : 'Data-driven',
                      style: TextStyle(
                          fontSize: 9.5,
                          color: aiPowered
                              ? const Color(0xFF27AE60)
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recs.isEmpty)
          const AppCard(
            padding: EdgeInsets.all(16),
            child: Text('Insights will appear as you list and sell.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          )
        else
          for (var i = 0; i < recs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildInsightItem(
              icons[i % icons.length],
              colors[i % colors.length],
              recs[i].title,
              recs[i].body,
            ),
          ],
      ],
    );
  }

  Widget _buildInsightItem(
      dynamic icon, Color color, String title, String body) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: HugeIcon(icon: icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  DonutChartPainter(
      {required this.goodPct,
      required this.soonPct,
      required this.rescuePct});
  final double goodPct, soonPct, rescuePct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const stroke = 12.0;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
    canvas.drawCircle(center, radius, track);

    final segments = [
      (goodPct, const Color(0xFF27AE60)),
      (soonPct, const Color(0xFFF2994A)),
      (rescuePct, const Color(0xFFD32F2F)),
    ];

    var start = -pi / 2;
    const gap = 0.08;
    for (final (pct, color) in segments) {
      if (pct <= 0) continue;
      final sweep = 2 * pi * (pct / 100) - gap;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter old) =>
      old.goodPct != goodPct ||
      old.soonPct != soonPct ||
      old.rescuePct != rescuePct;
}
