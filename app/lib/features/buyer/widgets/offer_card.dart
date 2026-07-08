import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/models/freshness.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/freshness_countdown.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/produce_image.dart';
import '../domain/offer.dart';
import 'favorite_heart.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, this.onTap});

  final Offer offer;
  final VoidCallback? onTap;

  Color get _tint => switch (offer.liveBand()) {
    FreshnessBand.good => AppColors.successSurface,
    FreshnessBand.useSoon => AppColors.warningSurface,
    FreshnessBand.rescue => AppColors.dangerSurface,
  };

  Color get _urgencyColor => switch (offer.liveBand()) {
    FreshnessBand.rescue => const Color(0xFFF23E3E),
    FreshnessBand.useSoon => const Color(0xFFF2994A),
    FreshnessBand.good => const Color(0xFF27AE60),
  };

  String get _freshnessLabel => switch (offer.liveBand()) {
    FreshnessBand.rescue => 'Rescue\n(0-6h)',
    FreshnessBand.useSoon => 'Use soon\n(6-12h)',
    FreshnessBand.good => offer.totalHours != null && offer.totalHours! > 24
        ? 'Fresh\n(24h+)'
        : 'Best price\n(12-24h)',
  };

  @override
  Widget build(BuildContext context) {
    final hasSavings = offer.liveSavingsPct() > 0;
    final price = offer.livePrice();

    return Pressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Overlays on the left
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: 'offer-${offer.id}',
                        child: ProduceImage(
                          imageUrl: offer.imageUrl,
                          tint: _tint,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: FavoriteHeart(offerId: offer.id),
                    ),
                    if (offer.liveSavingsPct() > 30 || offer.organic)
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
                                'BEST DEAL',
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
            // Middle Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          offer.vegetable,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: Color(0xFF27AE60),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedStore01,
                        color: AppColors.textMuted,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          offer.vendorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        color: AppColors.textMuted,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.distanceKm.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
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
                        label: '${offer.availableKg.toInt()} kg left',
                      ),
                      _tag(
                        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                        label: offer.liveBand() == FreshnessBand.good ? 'Grade A+' : 'Grade A',
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
                if (offer.hasClock)
                  FreshnessCountdownPill(
                    expiresAt: offer.expiresAt!,
                    totalHours: offer.totalHours!,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      offer.timeRange,
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
                if (hasSavings)
                  Text(
                    '₹${offer.marketPrice.toInt()}/kg',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${price.toInt()}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _urgencyColor,
                      ),
                    ),
                    Text(
                      '/kg',
                      style: TextStyle(
                        fontSize: 12,
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

  Widget _tag({required List<List<dynamic>> icon, required String label}) {
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
}
