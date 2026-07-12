import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/models/freshness.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/freshness_countdown.dart';
import '../../../core/widgets/motion.dart';
import '../domain/listing.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onUpdateStock,
    this.onEdit,
    this.onDelete,
  });

  final Listing listing;
  final VoidCallback? onUpdateStock;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color get _tint => switch (listing.liveBand()) {
    FreshnessBand.good => AppColors.successSurface,
    FreshnessBand.useSoon => AppColors.warningSurface,
    FreshnessBand.rescue => AppColors.dangerSurface,
  };

  Color get _urgencyColor => switch (listing.liveBand()) {
    FreshnessBand.rescue => const Color(0xFFF23E3E),
    FreshnessBand.useSoon => const Color(0xFFF2994A),
    FreshnessBand.good => const Color(0xFF27AE60),
  };

  String get _freshnessLabel => switch (listing.liveBand()) {
    FreshnessBand.rescue => 'Rescue\n(0-6h)',
    FreshnessBand.useSoon => 'Use soon\n(6-12h)',
    FreshnessBand.good => listing.totalHours != null && listing.totalHours! > 24
        ? 'Fresh\n(24h+)'
        : 'Best price\n(12-24h)',
  };

  @override
  Widget build(BuildContext context) {
    final price = listing.livePricePerKg();

    return Pressable(
      onTap: onUpdateStock ?? onEdit,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: listing.imagePath != null && listing.imagePath!.isNotEmpty
                          ? Image.file(File(listing.imagePath!), fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallbackImage())
                          : listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                              ? Image.network(listing.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallbackImage())
                              : _fallbackImage(),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                        ),
                      ),
                    ),
                    if (listing.organic)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedStar,
                                color: Colors.white,
                                size: 8,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'ORGANIC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Middle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          listing.vegetable,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: Color(0xFF27AE60),
                        size: 13,
                      ),
                      if (onDelete != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: onDelete,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedDelete02,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        color: AppColors.textMuted,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'K.R. Market, Bengaluru',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _tag(
                        icon: HugeIcons.strokeRoundedShoppingBag01,
                        label: '${listing.quantityKg.toInt()} kg left',
                      ),
                      _tag(
                        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                        label: listing.liveBand() == FreshnessBand.good ? 'Grade A+' : listing.liveBand() == FreshnessBand.useSoon ? 'Grade A' : 'Grade B',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right Pricing / Countdown Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (listing.hasClock)
                  FreshnessCountdownPill(
                    expiresAt: listing.expiresAt!,
                    totalHours: listing.totalHours!,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      listing.timeRange,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _urgencyColor,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  _freshnessLabel,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _urgencyColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${price.toInt()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _urgencyColor,
                      ),
                    ),
                    Text(
                      '/kg',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _urgencyColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag({required dynamic icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: AppColors.textSecondary, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedLeaf02,
        size: 32,
        color: AppColors.primary.withValues(alpha: 0.55),
      ),
    );
  }
}
