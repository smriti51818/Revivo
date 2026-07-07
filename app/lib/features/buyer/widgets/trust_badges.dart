import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// "Trusted" pill — auto-earned by vendors with 10+ orders at 4.3★+.
class TrustedVendorBadge extends StatelessWidget {
  const TrustedVendorBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded,
              size: compact ? 11 : 13, color: AppColors.primary),
          const SizedBox(width: 3),
          Text('Trusted',
              style: TextStyle(
                fontSize: compact ? 9.5 : 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              )),
        ],
      ),
    );
  }
}

/// Compact rating readout: ⭐ 4.6 (128).
class RatingPill extends StatelessWidget {
  const RatingPill({
    super.key,
    required this.rating,
    required this.reviews,
    this.dense = false,
  });

  final double rating;
  final int reviews;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: dense ? 13 : 15, color: AppColors.warning),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: dense ? 11.5 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '($reviews)',
          style: TextStyle(
            fontSize: dense ? 10.5 : 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
