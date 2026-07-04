import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/band_chip.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/rescue.dart';

/// Shared card for a rescue, with an optional [action] slot for role-specific
/// buttons (accept, claim, mark picked up / delivered).
class RescueCard extends StatelessWidget {
  const RescueCard({
    super.key,
    required this.rescue,
    this.action,
    this.showNgo = false,
  });

  final Rescue rescue;
  final Widget? action;
  final bool showNgo;

  ChipTone get _tone => switch (rescue.status) {
        RescueStatus.offered => ChipTone.warning,
        RescueStatus.accepted => ChipTone.info,
        RescueStatus.assigned => ChipTone.info,
        RescueStatus.pickedUp => ChipTone.warning,
        RescueStatus.delivered => ChipTone.success,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rescue.vegetable,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${rescue.vendorName} · ${rescue.pickupArea}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusChip(label: rescue.status.label, tone: _tone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _meta(Icons.scale_outlined, formatKg(rescue.quantityKg)),
              const SizedBox(width: AppSpacing.lg),
              _meta(Icons.restaurant_outlined,
                  '~${rescue.estimatedMeals} meals'),
              const SizedBox(width: AppSpacing.lg),
              _meta(Icons.place_outlined,
                  '${rescue.distanceKm.toStringAsFixed(1)} km'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              BandChip(band: rescue.band, timeRange: rescue.timeRange),
              if (showNgo && rescue.ngoName != null) ...[
                const Spacer(),
                Text(
                  rescue.ngoName!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
        ],
      );
}
