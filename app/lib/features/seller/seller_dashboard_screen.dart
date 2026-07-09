import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/discovery/vendor_directory.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/location_picker_sheet.dart';
import '../../core/widgets/app_card.dart';
import 'application/listings_providers.dart';
import 'application/vendor_orders_providers.dart';
import 'widgets/listing_card.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsProvider);
    final name = ref.watch(sessionProvider)?.name ?? 'Vendor';
    final location = vendorInfo(name).areaLabel;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildGreenHeader(context, ref, name, location),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(vendorOrdersProvider.notifier).reload();
                ref.invalidate(listingsProvider);
                await ref.read(listingsProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [

                  _buildActiveListingsHeader(context),
                  const SizedBox(height: 8),
                  listingsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(child: Text('Could not load listings: $e')),
                    ),
                    data: (items) => items.isEmpty
                        ? _empty()
                        : Column(
                            children: [
                              for (final listing in items) ...[
                                ListingCard(
                                  listing: listing,
                                  onUpdateStock: () => context.push('/seller/update-stock', extra: listing),
                                  onEdit: () => context.push('/seller/update-stock', extra: listing),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  _buildBottomBanner(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenHeader(BuildContext context, WidgetRef ref, String name, String location) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, $name 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => showLocationPicker(context, ref),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation01,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowDown01,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedStore02, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Seller',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildActiveListingsHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Active Listings',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => context.push('/seller/listings'),
          child: const Row(
            children: [
              Text(
                'View all',
                style: TextStyle(color: Color(0xFF27AE60), fontSize: 11, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 2),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 11, color: Color(0xFF27AE60)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBanner(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFEDFBF4),
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(icon: HugeIcons.strokeRoundedLeaf02, size: 16, color: Color(0xFF27AE60)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep your stock updated',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  'Update quantities and prices to reach more buyers and reduce waste.',
                  style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push('/seller/add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Add New Listing +',
              style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => const Padding(
        padding: EdgeInsets.only(top: 56),
        child: Center(
          child: Column(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedPackage,
                  size: 40, color: AppColors.textMuted),
              SizedBox(height: AppSpacing.md),
              Text('No listings yet',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              SizedBox(height: 2),
              Text('Tap + to list your surplus produce',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
}
