import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import 'application/insights_providers.dart';
import 'domain/seller_insights.dart';

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
      backgroundColor: const Color(0xFF0E692D),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: insightsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Could not load insights: $e')),
                    data: (insights) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildPeriodFilter(),
                        const SizedBox(height: 12),
                        _buildTopRow(insights),
                        const SizedBox(height: 16),
                        _buildEarningsOverview(insights.earnings),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Colors.white,
              size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insights',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                Text('Track your impact, performance and growth',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
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
                ? CustomPaint(
                    painter: EarningsChartPainter(
                      labels: earnings.labels,
                      values: earnings.values,
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
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$total',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const Text('Active',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
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
          const SizedBox(height: 12),
          Center(
            child: Text('View all produce >',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProduceRow(MoverRow mover) {
    final emoji = _vegEmoji[mover.vegetable] ?? '🥬';
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

class EarningsChartPainter extends CustomPainter {
  EarningsChartPainter({required this.labels, required this.values});
  final List<String> labels;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final n = values.length;
    final maxValue = values.reduce(max);

    final paintLine = Paint()
      ..color = const Color(0xFF27AE60)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const yCount = 5;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const leftPadding = 40.0;
    const bottomPadding = 20.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    // Nice y-axis top: round the max up so labels read cleanly.
    final axisTop = maxValue <= 0 ? 500.0 : _niceCeil(maxValue);
    final yStep = axisTop / (yCount - 1);
    for (int i = 0; i < yCount; i++) {
      final y = chartHeight / (yCount - 1) * i;
      final val = (yCount - 1 - i) * yStep;
      final label = val >= 1000
          ? '₹${(val / 1000).toStringAsFixed(1)}k'
          : '₹${val.toInt()}';
      textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        Paint()
          ..color = AppColors.border
          ..strokeWidth = 0.5,
      );
    }

    final xStep = n > 1 ? chartWidth / (n - 1) : chartWidth;
    for (int i = 0; i < n; i++) {
      final x = leftPadding + i * xStep;
      final label = i < labels.length ? labels[i] : '';
      textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height - 14));
    }

    final path = Path();
    for (int i = 0; i < n; i++) {
      final x = leftPadding + i * xStep;
      final y = chartHeight - (values[i] / axisTop * chartHeight);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintLine);

    // Mark the peak point.
    final maxIdx = values.indexOf(maxValue);
    if (maxIdx >= 0 && maxValue > 0) {
      final mx = leftPadding + maxIdx * xStep;
      final my = chartHeight - (values[maxIdx] / axisTop * chartHeight);
      canvas.drawCircle(Offset(mx, my), 4,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(
          Offset(mx, my),
          4,
          Paint()
            ..color = const Color(0xFF27AE60)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  double _niceCeil(double v) {
    if (v <= 0) return 500;
    final mag = pow(10, (log(v) / ln10).floor()).toDouble();
    final n = v / mag;
    final nice = n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10;
    return nice * mag;
  }

  @override
  bool shouldRepaint(EarningsChartPainter old) =>
      old.values != values || old.labels != labels;
}
