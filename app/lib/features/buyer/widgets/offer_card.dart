import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/discovery/vendor_directory.dart';
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
    FreshnessBand.rescue => 'Rescue',
    FreshnessBand.useSoon => 'Use soon',
    FreshnessBand.good => offer.totalHours != null && offer.totalHours! > 24
        ? 'Fresh'
        : 'Best price',
  };

  @override
  Widget build(BuildContext context) {
    final hasSavings = offer.liveSavingsPct() > 0;
    final price = offer.livePrice();
    final grade = switch (offer.liveBand()) {
      FreshnessBand.good => 'Grade A+',
      FreshnessBand.useSoon => 'Grade A',
      FreshnessBand.rescue => 'Grade B',
    };

    return Pressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product image with badges ──────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 96,
                    height: 96,
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
                          child:
                              FavoriteHeart(offerId: offer.id, onSurface: false),
                        ),
                        // A single freshness ribbon along the bottom of the
                        // image — clean and unmistakable, like a real store card.
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            color: _urgencyColor.withValues(alpha: 0.92),
                            alignment: Alignment.center,
                            child: Text(
                              _freshnessLabel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // ── Title, vendor, tags ────────────────────────────────────
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
                          if (offer.organic) ...[
                            const SizedBox(width: 6),
                            _pill('Organic', AppColors.primaryDark,
                                AppColors.primarySurface),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedStore02,
                            color: AppColors.textMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              offer.vendorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (vendorInfo(offer.vendorName).trusted) ...[
                            const SizedBox(width: 3),
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                              color: AppColors.primary,
                              size: 12,
                            ),
                          ],
                          const SizedBox(width: 6),
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation01,
                            color: AppColors.textMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${offer.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 11.5,
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
                            label: grade,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            // ── Price + live countdown, on one clean line ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                    const Text(
                      '/kg',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (hasSavings) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹${offer.marketPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                if (offer.hasClock)
                  FreshnessCountdownPill(
                    expiresAt: offer.expiresAt!,
                    totalHours: offer.totalHours!,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      offer.timeRange,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _urgencyColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w800, color: fg),
        ),
      );

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
