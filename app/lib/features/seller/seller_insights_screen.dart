import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:revivo/core/theme/app_colors.dart';
import 'package:revivo/core/widgets/app_card.dart';

class SellerInsightsScreen extends StatelessWidget {
  const SellerInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTopRow(),
                      const SizedBox(height: 16),
                      _buildEarningsOverview(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildListingsPerformance()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTopPerformingProduce()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildImpact(),
                      const SizedBox(height: 16),
                      _buildRecentInsights(),
                      const SizedBox(height: 80),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Insights',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Track your impact, performance and growth',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'This Week',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            HugeIcons.strokeRoundedShoppingBag01,
            const Color(0xFF27AE60),
            'Total Earnings',
            '₹4,680',
            '+ 18% vs last week',
            true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            HugeIcons.strokeRoundedTag01,
            const Color(0xFF27AE60),
            'Total Listings',
            '28',
            '+ 12% vs last week',
            true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            HugeIcons.strokeRoundedShoppingBag02,
            const Color(0xFF2D9CDB),
            'Quantity Sold',
            '156 kg',
            '+ 22% vs last week',
            true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            HugeIcons.strokeRoundedRestaurant01,
            const Color(0xFFF2994A),
            'Meals Saved',
            '390',
            '+ 26% vs last week',
            true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    dynamic icon,
    Color iconColor,
    String title,
    String value,
    String change,
    bool isUp,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: icon is IconData
                ? Icon(icon, size: 20, color: iconColor)
                : HugeIcon(icon: icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: const Color(0xFF27AE60),
                  size: 16,
                ),
                Text(
                  change,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsOverview() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Earnings Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    color: const Color(0xFF27AE60),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 12,
                    height: 2,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Last Week',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(painter: EarningsChartPainter()),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsPerformance() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Listings Performance',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CustomPaint(
                  painter: DonutChartPainter(),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '28',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLegendItem(
                const Color(0xFF27AE60),
                'Sold',
                '18',
                '(64%)',
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                const Color(0xFF2D9CDB),
                'Active',
                '7',
                '(25%)',
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                const Color(0xFFF2C94C),
                'Expired',
                '2',
                '(7%)',
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                const Color(0xFFBDBDBD),
                'Unsold',
                '1',
                '(4%)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value, String pct) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 4),
        Text(
          pct,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTopPerformingProduce() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Performing Produce',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProduceRow(
            'assets/images/tomato.png',
            'Tomato',
            '78 kg sold',
            '₹2,210',
          ),
          const SizedBox(height: 12),
          _buildProduceRow(
            'assets/images/spinach.png',
            'Spinach',
            '32 kg sold',
            '₹840',
          ),
          const SizedBox(height: 12),
          _buildProduceRow(
            'assets/images/okra.png',
            'Okra',
            '18 kg sold',
            '₹520',
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'View all produce >',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF27AE60),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProduceRow(
    String img,
    String name,
    String subtitle,
    String price,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.eco, color: Colors.green, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF27AE60),
          ),
        ),
      ],
    );
  }

  Widget _buildImpact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Impact You\'re Creating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildImpactCol(
                  HugeIcons.strokeRoundedLeaf02,
                  const Color(0xFF27AE60),
                  '156 kg',
                  'Food kept from waste',
                  '+ 22% vs last week',
                ),
              ),
              Container(width: 1, height: 60, color: AppColors.border),
              Expanded(
                child: _buildImpactCol(
                  HugeIcons.strokeRoundedUserMultiple,
                  const Color(0xFF2D9CDB),
                  '390',
                  'Meals saved',
                  '+ 26% vs last week',
                ),
              ),
              Container(width: 1, height: 60, color: AppColors.border),
              Expanded(
                child: _buildImpactCol(
                  Icons.currency_rupee,
                  const Color(0xFFF2994A),
                  '₹2,340',
                  'Buyer savings',
                  '+ 20% vs last week',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactCol(
    dynamic icon,
    Color color,
    String value,
    String subtitle,
    String change,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: icon is IconData
              ? Icon(icon, size: 18, color: color)
              : HugeIcon(icon: icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_drop_up, color: Color(0xFF27AE60), size: 14),
            Text(
              change,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF27AE60),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Insights',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          HugeIcons.strokeRoundedChartLineData01,
          const Color(0xFF27AE60),
          'Great week! 🎉',
          'Your earnings are 18% higher than last week.',
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          HugeIcons.strokeRoundedTime01,
          const Color(0xFF7CB342),
          'Quick tip',
          'Tomatoes listings sell 30% faster when added in the morning.',
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          HugeIcons.strokeRoundedTag01,
          const Color(0xFFF2994A),
          'Opportunity',
          'Consider listing more Leafy Greens - high demand this week!',
        ),
      ],
    );
  }

  Widget _buildInsightItem(
    dynamic icon,
    Color color,
    String title,
    String body,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(icon: icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
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
      (64.0, const Color(0xFF27AE60)),
      (25.0, const Color(0xFF2D9CDB)),
      (7.0, const Color(0xFFF2C94C)),
      (4.0, const Color(0xFFBDBDBD)),
    ];
    var start = -pi / 2;
    const gap = 0.08;
    for (final (pct, color) in segments) {
      final sweep = 2 * pi * (pct / 100) - gap;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EarningsChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine1 = Paint()
      ..color = const Color(0xFF27AE60)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final paintLine2 = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final yLabels = ['₹2.0k', '₹1.5k', '₹1.0k', '₹500', '₹0'];
    final xLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    double leftPadding = 36;
    double bottomPadding = 20;
    double chartWidth = size.width - leftPadding;
    double chartHeight = size.height - bottomPadding;

    // Draw Y axis labels & horizontal lines
    for (int i = 0; i < 5; i++) {
      double y = i * (chartHeight / 4);
      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      );
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

    // Draw X axis labels
    double xStep = chartWidth / 6;
    for (int i = 0; i < 7; i++) {
      double x = leftPadding + i * xStep;
      textPainter.text = TextSpan(
        text: xLabels[i],
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 14),
      );
    }

    // Data points
    final data1 = [0.2, 0.4, 0.45, 0.4, 0.6, 0.65, 0.4];
    final data2 = [0.1, 0.2, 0.3, 0.25, 0.4, 0.45, 0.3];

    Path path1 = Path();
    Path path2 = Path();

    for (int i = 0; i < 7; i++) {
      double x = leftPadding + i * xStep;
      double y1 = chartHeight - (data1[i] * chartHeight);
      double y2 = chartHeight - (data2[i] * chartHeight);

      if (i == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
      }
    }

    canvas.drawPath(path1, paintLine1);
    // Draw dashed line for path 2 (simplification: draw solid for now, or use a dashed path generator)
    // To make it simple, let's just draw it dotted.
    for (int i = 0; i < 7; i++) {
      if (i > 0) {
        double x1 = leftPadding + (i - 1) * xStep;
        double y2_prev = chartHeight - (data2[i - 1] * chartHeight);
        double x2 = leftPadding + i * xStep;
        double y2_curr = chartHeight - (data2[i] * chartHeight);
        // Draw 5 dashes between points
        for (int j = 1; j <= 5; j += 2) {
          double dx1 = x1 + (x2 - x1) * (j - 1) / 5;
          double dy1 = y2_prev + (y2_curr - y2_prev) * (j - 1) / 5;
          double dx2 = x1 + (x2 - x1) * j / 5;
          double dy2 = y2_prev + (y2_curr - y2_prev) * j / 5;
          canvas.drawLine(Offset(dx1, dy1), Offset(dx2, dy2), paintLine2);
        }
      }
    }

    // Draw the tooltip point on Thu (index 3)
    double targetX = leftPadding + 3 * xStep;
    double targetY = chartHeight - (data1[3] * chartHeight);

    // Dotted vertical line
    canvas.drawLine(
      Offset(targetX, targetY),
      Offset(targetX, chartHeight),
      Paint()
        ..color = const Color(0xFF27AE60)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // Circle point
    canvas.drawCircle(
      Offset(targetX, targetY),
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(targetX, targetY),
      4,
      Paint()
        ..color = const Color(0xFF27AE60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Tooltip box
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(targetX, targetY - 24),
        width: 44,
        height: 24,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF0F7033));
    textPainter.text = const TextSpan(
      text: '₹920',
      style: TextStyle(
        fontSize: 10,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(targetX - textPainter.width / 2, targetY - 32),
    );

    // Little triangle pointing down
    Path triangle = Path()
      ..moveTo(targetX - 4, targetY - 12)
      ..lineTo(targetX + 4, targetY - 12)
      ..lineTo(targetX, targetY - 6)
      ..close();
    canvas.drawPath(triangle, Paint()..color = const Color(0xFF0F7033));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
