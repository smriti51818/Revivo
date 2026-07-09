import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/discovery/vendor_directory.dart';
import '../../core/format.dart';
import '../../core/models/freshness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import 'application/marketplace_providers.dart';
import 'domain/offer.dart';

/// A sweeping "rescue radar" — your hotel at the centre, nearby surplus plotted
/// by distance + direction, coloured by freshness band. A dependency-free stand-in
/// for a full map that still lands the spatial "surplus is nearby right now" wow.
class RescueMapScreen extends ConsumerStatefulWidget {
  const RescueMapScreen({super.key});

  @override
  ConsumerState<RescueMapScreen> createState() => _RescueMapScreenState();
}

class _RescueMapScreenState extends ConsumerState<RescueMapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;
  static const double _maxKm = 3.5;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Color _bandColor(FreshnessBand b) => switch (b) {
        FreshnessBand.good => AppColors.success,
        FreshnessBand.useSoon => AppColors.warning,
        FreshnessBand.rescue => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(offersProvider).valueOrNull ?? const <Offer>[];
    final nearby = offers.where((o) => !o.isExpired()).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final plotted = nearby.take(14).toList();
    final actualMaxKm = plotted.isEmpty ? 3.5 : (plotted.last.distanceKm > 3.5 ? plotted.last.distanceKm : 3.5);

    return Scaffold(
      appBar: AppBar(title: const Text('Rescue radar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.screen, AppSpacing.screen, 40),
          children: [
            Text(
              '${plotted.length} surplus lots within ${_maxKm.toStringAsFixed(0)} km',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            const Text('Live positions around your hotel · tap a dot to open',
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            _radar(plotted, actualMaxKm),
            const SizedBox(height: AppSpacing.lg),
            _legend(),
            const SizedBox(height: AppSpacing.lg),
            for (final o in plotted) ...[
              _row(o),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _radar(List<Offer> offers, double actualMaxKm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, 340.0);
        final center = size / 2;
        final usable = center - 26;
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _sweep,
                  builder: (context, _) => CustomPaint(
                    size: Size(size, size),
                    painter: _RadarPainter(angle: _sweep.value * 2 * pi),
                  ),
                ),
                // Centre "you" marker.
                Positioned(
                  left: center - 15,
                  top: center - 15,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const HugeIcon(icon: HugeIcons.strokeRoundedRestaurant01,
                        size: 15, color: Colors.white),
                  ),
                ),
                for (final o in offers) _dot(o, center, usable, actualMaxKm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dot(Offer o, double center, double usable, double actualMaxKm) {
    final info = vendorInfo(o.vendorName);
    final r = (o.distanceKm / actualMaxKm).clamp(0.12, 1.0) * usable;
    final dx = center + r * cos(info.bearing);
    final dy = center + r * sin(info.bearing);
    final color = _bandColor(o.liveBand());
    return Positioned(
      left: dx - 13,
      top: dy - 13,
      child: GestureDetector(
        onTap: () => context.push('/buyer/product', extra: o),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1),
            ],
          ),
          child: const HugeIcon(icon: HugeIcons.strokeRoundedLeaf02, size: 13, color: Colors.white),
        ),
      ),
    );
  }

  Widget _legend() {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        item(AppColors.success, 'Good'),
        item(AppColors.warning, 'Use soon'),
        item(AppColors.danger, 'Rescue'),
      ],
    );
  }

  Widget _row(Offer o) {
    final color = _bandColor(o.liveBand());
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      onTap: () => context.push('/buyer/product', extra: o),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.vegetable,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700)),
                Text(o.vendorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${formatMoney(o.livePrice())}/kg',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              Text('${o.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.angle});
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 - 4;

    // Backdrop.
    canvas.drawCircle(
        center, maxR, Paint()..color = AppColors.primarySurface.withValues(alpha: 0.4));

    // Range rings.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.primary.withValues(alpha: 0.22);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxR * i / 3, ring);
    }
    // Cross axes.
    canvas.drawLine(Offset(center.dx - maxR, center.dy),
        Offset(center.dx + maxR, center.dy), ring);
    canvas.drawLine(Offset(center.dx, center.dy - maxR),
        Offset(center.dx, center.dy + maxR), ring);

    // Sweeping comet.
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.0),
          AppColors.primary.withValues(alpha: 0.28),
          AppColors.primary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.08, 0.2],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, sweep);

    // Leading edge line.
    final edge = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      center,
      Offset(center.dx + maxR * cos(angle), center.dy + maxR * sin(angle)),
      edge,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.angle != angle;
}
