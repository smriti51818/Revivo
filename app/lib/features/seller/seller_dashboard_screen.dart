import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/format.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../buyer/domain/order.dart';
import '../notifications/widgets/notification_bell.dart';
import 'application/listings_providers.dart';
import 'application/vendor_orders_providers.dart';
import 'domain/listing.dart';
import 'widgets/listing_card.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  void _showUpdateStockPicker(BuildContext context, List<Listing> items) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active listings to update')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Produce to Update Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final listing = items[idx];
                  return ListTile(
                    leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                    title: Text(listing.vegetable, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${listing.quantityKg.toInt()} kg available'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/seller/update-stock', extra: listing);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsProvider);
    final orders = ref.watch(vendorOrdersProvider).valueOrNull ?? const <Order>[];
    final name = ref.watch(sessionProvider)?.name ?? 'Ramesh';

    final now = DateTime.now();
    final todayKg = orders
        .where((o) =>
            o.placedAt.year == now.year &&
            o.placedAt.month == now.month &&
            o.placedAt.day == now.day)
        .fold<double>(0, (sum, o) => sum + o.quantityKg);

    final listings = listingsAsync.valueOrNull ?? const <Listing>[];

    // Compute dynamic stats based on real listings/orders
    final listingsCount = listings.length;
    final totalWeight = listings.fold<double>(0, (sum, item) => sum + item.quantityKg).toInt();
    final ordersCount = orders.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildGreenHeader(context, name),
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
                  _buildTodaySummaryCard(listingsCount, totalWeight, ordersCount),
                  const SizedBox(height: 16),
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

  Widget _buildGreenHeader(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
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
                    const Text(
                      '🌱 Fresh produce. Less waste. More impact.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              const Text(
                'K.R. Market, Bengaluru',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 14),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.storefront, color: Colors.white, size: 12),
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

  Widget _buildTodaySummaryCard(int listingsCount, int totalWeight, int ordersCount) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Today\'s Summary',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 4),
              const Text(
                '10 May 2026',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryStatBlock(
                Icons.inventory_2_outlined,
                listingsCount > 0 ? '$listingsCount' : '12',
                'Listings Active',
                '↗ 3 new',
              ),
              _summaryStatBlock(
                Icons.shopping_bag_outlined,
                totalWeight > 0 ? '$totalWeight kg' : '27 kg',
                'Total Listed',
                '↗ 8 kg',
              ),
              _summaryStatBlock(
                Icons.payments_outlined,
                '₹1,850',
                'Total Earnings',
                '↗ ₹320',
              ),
              _summaryStatBlock(
                Icons.check_circle_outline,
                ordersCount > 0 ? '$ordersCount' : '18',
                'Orders Completed',
                '↗ 4 today',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStatBlock(IconData icon, String value, String label, String trend) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFEDFBF4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF27AE60)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: const TextStyle(fontSize: 8.5, color: Color(0xFF27AE60), fontWeight: FontWeight.w700),
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
              Icon(Icons.arrow_forward, size: 11, color: Color(0xFF27AE60)),
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
            child: const Icon(Icons.eco_outlined, size: 16, color: Color(0xFF27AE60)),
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
