import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/discovery/vendor_directory.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import 'trust_badges.dart';

/// The "Quality Confidence Card" from the spec's five-layer trust model —
/// rating, AI defect screening, GPS-verified photo, and fulfilment record — so
/// the buyer can commit with confidence before pickup.
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
          _check('AI-screened produce',
              'Vendor photos are screened for visible defects on Rekognition'),
          const SizedBox(height: 10),
          _check('GPS-verified listings',
              'Photos are captured and tagged at the vendor stall'),
          const SizedBox(height: 10),
          _check('${info.completedOrders} orders fulfilled',
              'Pay on pickup — inspect before you accept'),
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
