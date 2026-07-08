import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/models/freshness.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/listing.dart';

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

  @override
  Widget build(BuildContext context) {
    // Determine band styling
    final band = listing.liveBand();
    final Color bandColor;
    final Color bandBg;
    final String bandLabel;
    
    switch (band) {
      case FreshnessBand.rescue:
        bandColor = const Color(0xFFD32F2F);
        bandBg = const Color(0xFFFFEBEE);
        bandLabel = 'Rescue';
        break;
      case FreshnessBand.useSoon:
        bandColor = const Color(0xFFE65100);
        bandBg = const Color(0xFFFFF3E0);
        bandLabel = 'Use soon';
        break;
      case FreshnessBand.good:
        bandColor = const Color(0xFF2E7D32);
        bandBg = const Color(0xFFE8F5E9);
        bandLabel = 'Fresh';
        break;
    }

    final diff = listing.expiresAt != null ? listing.expiresAt!.difference(DateTime.now()) : null;
    final timerText = diff != null && diff.inSeconds > 0
        ? '${diff.inHours.toString().padLeft(2, '0')}h ${(diff.inMinutes % 60).toString().padLeft(2, '0')}m left'
        : '0h 18m left'; // Fallback mockup time

    return GestureDetector(
      onTap: onUpdateStock,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Left: Image with Stack
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: listing.imagePath != null && listing.imagePath!.isNotEmpty
                        ? Image.file(File(listing.imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackImage())
                        : listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                            ? Image.network(listing.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackImage())
                            : _fallbackImage(),
                  ),
                ),
                // ACTIVE Tag
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                    ),
                  ),
                ),
                // Heart Overlay
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const HugeIcon(icon: HugeIcons.strokeRoundedFavourite, size: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Middle: Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      listing.vegetable,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, size: 12, color: Color(0xFF27AE60)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Fresh • Grade A',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedPackage, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${listing.quantityKg.toInt()} kg available',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 11, color: AppColors.textMuted),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'K.R. Market, Bengaluru',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: Pricing / Timer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Freshness container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: bandBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bandLabel,
                      style: TextStyle(color: bandColor, fontSize: 9.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 10, color: bandColor),
                        const SizedBox(width: 2),
                        Text(
                          timerText,
                          style: TextStyle(color: bandColor, fontSize: 9, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${listing.basePrice.toInt()}/kg',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${listing.recommendedPrice.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: bandColor,
                          ),
                        ),
                        Text(
                          '/kg',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: bandColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _fallbackImage() {
    return Image.asset(
      'assets/images/tomato.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: AppColors.primarySurface),
    );
  }
}
