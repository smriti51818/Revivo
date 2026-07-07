import 'dart:async';

import 'package:flutter/material.dart';

import '../format.dart';
import '../freshness/live_clock.dart';
import '../models/freshness.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Rebuilds once a second, handing the live remaining time + freshness band to
/// a builder. This is the beating heart of Revivo's "produce is a decaying
/// asset with a live countdown" thesis — one ticker, reused everywhere.
class FreshnessTicker extends StatefulWidget {
  const FreshnessTicker({
    super.key,
    required this.expiresAt,
    required this.totalHours,
    required this.builder,
  });

  final DateTime expiresAt;
  final double totalHours;
  final Widget Function(BuildContext, Duration remaining, FreshnessBand band)
      builder;

  @override
  State<FreshnessTicker> createState() => _FreshnessTickerState();
}

class _FreshnessTickerState extends State<FreshnessTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = widget.expiresAt.difference(now);
    final band = LiveClock.band(
      expiresAt: widget.expiresAt,
      totalHours: widget.totalHours,
      now: now,
    );
    return widget.builder(context, remaining, band);
  }
}

/// Compact band-colored pill with a ticking countdown — for cards and overlays.
class FreshnessCountdownPill extends StatelessWidget {
  const FreshnessCountdownPill({
    super.key,
    required this.expiresAt,
    required this.totalHours,
    this.showBandLabel = false,
  });

  final DateTime expiresAt;
  final double totalHours;
  final bool showBandLabel;

  ({Color fg, Color bg}) _tones(FreshnessBand band) => switch (band) {
        FreshnessBand.good =>
          (fg: AppColors.success, bg: AppColors.successSurface),
        FreshnessBand.useSoon =>
          (fg: AppColors.warning, bg: AppColors.warningSurface),
        FreshnessBand.rescue =>
          (fg: AppColors.danger, bg: AppColors.dangerSurface),
      };

  @override
  Widget build(BuildContext context) {
    return FreshnessTicker(
      expiresAt: expiresAt,
      totalHours: totalHours,
      builder: (context, remaining, band) {
        final tones = _tones(band);
        final expired = remaining.inSeconds <= 0;
        final urgent = band == FreshnessBand.rescue;
        final label = expired
            ? 'Expired'
            : showBandLabel
                ? '${band.label} · ${formatCountdown(remaining)}'
                : formatCountdown(remaining);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: expired ? AppColors.surfaceAlt : tones.bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                urgent ? Icons.bolt : Icons.schedule,
                size: 13,
                color: expired ? AppColors.textMuted : tones.fg,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: expired ? AppColors.textMuted : tones.fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
