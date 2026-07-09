import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/discovery/vendor_directory.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import 'trust_badges.dart';

/// The "Quality & trust" card — states only true, generic facts the buyer can
/// rely on: the vendor's rating, their fulfilment record, and Revivo's
/// pay-on-pickup, inspect-before-you-accept policy. It makes no per-item
/// verification claims (no "this photo was AI-screened" / "GPS-verified").
class QualityCard extends StatelessWidget {
  const QualityCard({super.key, required this.vendorName});

  final String vendorName;

  @override
  Widget build(BuildContext context) {
    final info = vendorInfo(vendorName);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Quality & trust',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              RatingPill(rating: info.rating, reviews: info.reviews),
              if (info.trusted) ...[
                const SizedBox(width: 8),
                const TrustedVendorBadge(compact: true),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _check('Pay on pickup',
              'Inspect the produce in person and only pay once you accept it'),
          const SizedBox(height: 10),
          _check('${info.completedOrders} orders fulfilled',
              'This vendor has completed ${info.completedOrders} pickups on Revivo'),
          const SizedBox(height: 10),
          _check('${info.rating.toStringAsFixed(1)}★ from ${info.reviews} buyers',
              'Average rating across past Revivo pickups'),
        ],
      ),
    );
  }

  Widget _check(String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01,
              size: 13, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
