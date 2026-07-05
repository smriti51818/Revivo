import 'package:flutter/material.dart';

import '../../../core/models/freshness.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/band_chip.dart';
import '../../../core/widgets/produce_image.dart';
import '../domain/listing.dart';

String formatMoney(double value) {
  final whole = value == value.roundToDouble();
  return '₹${whole ? value.toStringAsFixed(0) : value.toStringAsFixed(2)}';
}

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onUpdateStock,
    this.onEdit,
  });

  final Listing listing;
  final VoidCallback? onUpdateStock;
  final VoidCallback? onEdit;

  Color get _tint => switch (listing.band) {
        FreshnessBand.good => AppColors.successSurface,
        FreshnessBand.useSoon => AppColors.warningSurface,
        FreshnessBand.rescue => AppColors.dangerSurface,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                    child: ProduceImage(
                      imageUrl: listing.imageUrl,
                      tint: _tint,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        if (listing.organic)
                          _tag('ORGANIC', AppColors.textPrimary, Colors.white),
                        if (listing.isLowStock) ...[
                          if (listing.organic) const SizedBox(width: 6),
                          _tag('LOW STOCK', AppColors.danger, Colors.white),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: BandChip(
                      band: listing.band,
                      timeRange: listing.timeRange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.vegetable,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatMoney(listing.recommendedPrice)} / kg',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'REMAINING',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${listing.quantityKg.toStringAsFixed(listing.quantityKg == listing.quantityKg.roundToDouble() ? 0 : 1)} kg',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpdateStock,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Update stock'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 19, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
}
