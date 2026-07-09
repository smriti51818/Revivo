import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum ChipTone { neutral, success, warning, danger, info, done }

/// A small labelled status pill (order states, badges, tags).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.icon,
  });

  final String label;
  final ChipTone tone;
  final IconData? icon;

  ({Color fg, Color bg}) get _tones => switch (tone) {
        ChipTone.neutral =>
          (fg: AppColors.textSecondary, bg: AppColors.surfaceAlt),
        ChipTone.success =>
          (fg: AppColors.success, bg: AppColors.successSurface),
        ChipTone.warning =>
          (fg: AppColors.warning, bg: AppColors.warningSurface),
        ChipTone.danger => (fg: AppColors.danger, bg: AppColors.dangerSurface),
        ChipTone.info => (fg: AppColors.info, bg: AppColors.infoSurface),
        // A calm violet for "finished, all good" states — visually distinct
        // from the green (readyForPickup) and blue (confirmed) tones.
        ChipTone.done =>
          (fg: const Color(0xFF6D28D9), bg: const Color(0xFFEDE9FE)),
      };

  @override
  Widget build(BuildContext context) {
    final tones = _tones;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tones.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: tones.fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: tones.fg,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
