import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'application/listings_providers.dart';
import 'widgets/listing_card.dart';

class SellerListingsScreen extends ConsumerWidget {
  const SellerListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('My Listings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(listingsProvider);
          await ref.read(listingsProvider.future);
        },
        child: listingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load listings: $e')),
          data: (items) => items.isEmpty
              ? _empty(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final listing = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListingCard(
                        listing: listing,
                        onUpdateStock: () => context.push('/seller/update-stock', extra: listing),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(icon: HugeIcons.strokeRoundedPackage, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            const Text('No active listings',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Tap + to list your surplus produce',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/seller/add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Add New Listing', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}
