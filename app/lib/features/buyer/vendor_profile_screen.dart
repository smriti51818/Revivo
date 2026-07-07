import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/discovery/vendor_directory.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import 'application/marketplace_providers.dart';
import 'domain/offer.dart';
import 'widgets/cart_bar.dart';
import 'widgets/offer_card.dart';
import 'widgets/trust_badges.dart';

/// A vendor's storefront: reputation, trust signals, and everything they have
/// live right now — the Swiggy "restaurant page" applied to a surplus vendor.
class VendorProfileScreen extends ConsumerWidget {
  const VendorProfileScreen({super.key, required this.vendorName});

  final String vendorName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = vendorInfo(vendorName);
    final offers = ref.watch(offersProvider).valueOrNull ?? const <Offer>[];
    final mine = offers
        .where((o) => o.vendorName == vendorName && !o.isExpired())
        .toList()
      ..sort((a, b) {
        final ax = a.expiresAt, bx = b.expiresAt;
        if (ax == null || bx == null) return 0;
        return ax.compareTo(bx);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor')),
      bottomNavigationBar: const CartBar(),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            _header(info),
            const SizedBox(height: AppSpacing.md),
            _stats(info, mine.length),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Available now · ${mine.length}'),
            const SizedBox(height: AppSpacing.md),
            if (mine.isEmpty)
              _emptyOffers()
            else
              for (final o in mine) ...[
                OfferCard(
                  offer: o,
                  onTap: () => context.push('/buyer/product', extra: o),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }

  Widget _header(VendorInfo info) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                info.name.isNotEmpty ? info.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(info.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    if (info.trusted) const TrustedVendorBadge(),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      '${info.areaLabel} · ${info.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RatingPill(rating: info.rating, reviews: info.reviews),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats(VendorInfo info, int active) {
    return Row(
      children: [
        Expanded(child: _stat('$active', 'Live listings')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _stat(info.rating.toStringAsFixed(1), 'Avg rating')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _stat('${info.completedOrders}', 'Orders done')),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9.5,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }

  Widget _emptyOffers() => AppCard(
        color: AppColors.surfaceAlt,
        child: const Row(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 20, color: AppColors.textSecondary),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'No live surplus from this vendor right now — check back this evening.',
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
}
