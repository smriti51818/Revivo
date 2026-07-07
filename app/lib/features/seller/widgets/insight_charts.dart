import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/seller_insights.dart';

/// A donut of the seller's active listings by freshness band, with the total in
/// the middle — the "where's my risk" glance. Pure CustomPainter (no chart dep).
class BandRing extends StatelessWidget {
  const BandRing({
    super.key,
    required this.good,
    required this.useSoon,
    required this.rescue,
  });

  final int good;
  final int useSoon;
  final int rescue;

  int get _total => good + useSoon + rescue;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _RingPainter(good: good, useSoon: useSoon, rescue: rescue),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_total',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const Text('listed',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Freshness mix',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.sm),
                _legend(AppColors.success, 'Good', good),
                const SizedBox(height: 6),
                _legend(AppColors.warning, 'Use soon', useSoon),
                const SizedBox(height: 6),
                _legend(AppColors.danger, 'Rescue', rescue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label, int value) {
    final pct = _total == 0 ? 0 : (value / _total * 100).round();
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        Text('$value · $pct%',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.good, required this.useSoon, required this.rescue});
  final int good;
  final int useSoon;
  final int rescue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const stroke = 14.0;
    final total = good + useSoon + rescue;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surfaceAlt;
    canvas.drawCircle(center, radius, track);
    if (total == 0) return;

    final segments = [
      (good, AppColors.success),
      (useSoon, AppColors.warning),
      (rescue, AppColors.danger),
    ];
    var start = -pi / 2;
    const gap = 0.06;
    for (final (count, color) in segments) {
      if (count == 0) continue;
      final sweep = 2 * pi * count / total - gap;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
          sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.good != good || old.useSoon != useSoon || old.rescue != rescue;
}

/// Horizontal bars for the seller's top-selling vegetables, sized by kg sold.
class MoverBars extends StatelessWidget {
  const MoverBars({super.key, required this.movers});
  final List<MoverRow> movers;

  @override
  Widget build(BuildContext context) {
    final maxKg = movers.fold<double>(0, (m, r) => max(m, r.kg));
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < movers.length; i++) ...[
            _bar(movers[i], maxKg),
            if (i != movers.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  Widget _bar(MoverRow m, double maxKg) {
    final frac = maxKg <= 0 ? 0.0 : (m.kg / maxKg).clamp(0.04, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(m.vegetable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            Text('${formatKg(m.kg)} · ${formatMoney(m.revenue)}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
