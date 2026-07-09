import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/discovery/vendor_directory.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';

/// Seller reputation — the aggregate rating/count and recent reviews come from
/// the shared vendor directory (deterministic per vendor name), the same source
/// the buyer storefront uses, so both sides show the same numbers. Swapped for a
/// real reviews query once the backend aggregates them.
class SellerReviewsScreen extends ConsumerWidget {
  const SellerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(sessionProvider)?.name ?? 'Vendor';
    final info = vendorInfo(name);
    final reviews = vendorReviews(name);
    final filled = info.rating.round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    info.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => HugeIcon(
                              icon: HugeIcons.strokeRoundedStar,
                              size: 16,
                              color: index < filled
                                  ? AppColors.warning
                                  : AppColors.border,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on ${info.reviews} reviews',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        if (info.trusted) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: const [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                                size: 14,
                                color: Color(0xFF27AE60),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Trusted Vendor',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF27AE60)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Reviews from Buyers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            for (final r in reviews) ...[
              _buildReviewCard(r),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(VendorReview r) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    r.author[0],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  r.author,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                r.ago,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (index) => HugeIcon(
                icon: HugeIcons.strokeRoundedStar,
                size: 14,
                color: index < r.stars ? AppColors.warning : AppColors.border,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            r.text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
