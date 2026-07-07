import 'package:flutter/material.dart';

import '../../../core/discovery/vendor_directory.dart';
import '../../../core/format.dart';
import '../../../core/models/freshness.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/band_chip.dart';
import '../../../core/widgets/freshness_countdown.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/produce_image.dart';
import '../domain/offer.dart';
import 'favorite_heart.dart';
import 'trust_badges.dart';

/// Marketplace card for a single surplus offer.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, this.onTap});

  final Offer offer;
  final VoidCallback? onTap;

  Color get _tint => switch (offer.liveBand()) {
    FreshnessBand.good => AppColors.successSurface,
    FreshnessBand.useSoon => AppColors.warningSurface,
    FreshnessBand.rescue => AppColors.dangerSurface,
  };

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                height: 128,
                width: double.infinity,
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
                      top: 10,
                      left: 10,
                      child: Row(
                        children: [
                          if (offer.distanceKm > 0)
                            _pill(
                              icon: Icons.place_outlined,
                              label:
                                  '${offer.distanceKm.toStringAsFixed(1)} km',
                            ),
                          if (offer.organic) ...[
                            if (offer.distanceKm > 0) const SizedBox(width: 6),
                            _tag('ORGANIC'),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FavoriteHeart(offerId: offer.id),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: _LiveSavingsTag(offer: offer),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: offer.hasClock
                          ? FreshnessCountdownPill(
                              expiresAt: offer.expiresAt!,
                              totalHours: offer.totalHours!,
                            )
                          : BandChip(
                              band: offer.band,
                              timeRange: offer.timeRange,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          offer.vendorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (vendorInfo(offer.vendorName).trusted) ...[
                        const SizedBox(width: 5),
                        const TrustedVendorBadge(compact: true),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                RatingPill(
                  rating: vendorInfo(offer.vendorName).rating,
                  reviews: vendorInfo(offer.vendorName).reviews,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              offer.vegetable,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            FreshnessTicker(
              expiresAt:
                  offer.expiresAt ??
                  DateTime.now().add(const Duration(hours: 12)),
              totalHours: offer.totalHours ?? 24,
              builder: (context, _, _) {
                final price = offer.livePrice();
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${formatMoney(price)} / kg',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (offer.liveSavingsPct() > 0)
                      Text(
                        formatMoney(offer.marketPrice),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '${formatKg(offer.availableKg)} left',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({required IconData icon, required String label}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.textPrimary,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );
}

/// "X% off" badge that grows live as the freshness-decayed price drops.
class _LiveSavingsTag extends StatelessWidget {
  const _LiveSavingsTag({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return FreshnessTicker(
      expiresAt:
          offer.expiresAt ?? DateTime.now().add(const Duration(hours: 12)),
      totalHours: offer.totalHours ?? 24,
      builder: (context, _, _) {
        final pct = offer.liveSavingsPct();
        if (pct <= 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            '$pct% off',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }
}
