import 'package:flutter/material.dart';

import '../models/freshness.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Freshness band pill: colored dot + label, optionally with a time range.
class BandChip extends StatelessWidget {
  const BandChip({super.key, required this.band, this.timeRange});

  final FreshnessBand band;
  final String? timeRange;

  ({Color fg, Color bg}) get _tones => switch (band) {
        FreshnessBand.good =>
          (fg: AppColors.success, bg: AppColors.successSurface),
        FreshnessBand.useSoon =>
          (fg: AppColors.warning, bg: AppColors.warningSurface),
        FreshnessBand.rescue =>
          (fg: AppColors.danger, bg: AppColors.dangerSurface),
      };

  @override
  Widget build(BuildContext context) {
    final tones = _tones;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tones.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tones.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            timeRange == null ? band.label : '${band.label} · $timeRange',
            style: TextStyle(
              color: tones.fg,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
