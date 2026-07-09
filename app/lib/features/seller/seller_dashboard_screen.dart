import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../buyer/domain/order.dart';
import 'application/listings_providers.dart';
import 'application/vendor_orders_providers.dart';
import 'domain/listing.dart';
import 'widgets/listing_card.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsProvider);
    final orders = ref.watch(vendorOrdersProvider).valueOrNull ?? const <Order>[];
    final name = ref.watch(sessionProvider)?.name ?? 'Ramesh';

    final listings = listingsAsync.valueOrNull ?? const <Listing>[];

    final listingsCount = listings.length;
    final totalWeight = listings.fold<double>(0, (sum, item) => sum + item.quantityKg).toInt();
    final ordersCount = orders.length;
    final totalEarnings = orders.fold<double>(0, (s, o) => s + o.total);

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
                  _buildTodaySummaryCard(listingsCount, totalWeight, ordersCount, totalEarnings),
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
              const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              const Text(
                'K.R. Market, Bengaluru',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: Colors.white70, size: 14),
              const Spacer(),
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

  Widget _buildTodaySummaryCard(int listingsCount, int totalWeight, int ordersCount, double totalEarnings) {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
    final earningsStr = totalEarnings > 0
        ? '₹${totalEarnings.toInt()}'
        : '₹0';

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
              const HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryStatBlock(
                HugeIcons.strokeRoundedPackage,
                '$listingsCount',
                'Listings Active',
                listingsCount > 0 ? '↗ ${listingsCount} active' : '—',
              ),
              _summaryStatBlock(
                HugeIcons.strokeRoundedShoppingBag01,
                '$totalWeight kg',
                'Total Listed',
                totalWeight > 0 ? '↗ $totalWeight kg' : '—',
              ),
              _summaryStatBlock(
                HugeIcons.strokeRoundedMoney01,
                earningsStr,
                'Total Earnings',
                ordersCount > 0 ? '↗ $ordersCount orders' : '—',
              ),
              _summaryStatBlock(
                HugeIcons.strokeRoundedCheckmarkCircle02,
                '$ordersCount',
                'Orders',
                ordersCount > 0 ? '↗ all time' : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStatBlock(dynamic icon, String value, String label, String trend) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFEDFBF4),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(icon: icon, size: 16, color: const Color(0xFF27AE60)),
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
