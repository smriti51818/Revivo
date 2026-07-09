import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/freshness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/motion.dart';
import 'application/marketplace_providers.dart';
import 'widgets/offer_card.dart';

class BuyerEndingSoonScreen extends ConsumerWidget {
  const BuyerEndingSoonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Ending Soon',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (offers) {
          final endingSoonOffers =
              offers.where((o) => o.liveBand() == FreshnessBand.rescue).toList()
                ..sort((a, b) {
                  if (a.expiresAt == null && b.expiresAt == null) return 0;
                  if (a.expiresAt == null) return 1;
                  if (b.expiresAt == null) return -1;
                  return a.expiresAt!.compareTo(b.expiresAt!);
                });

          return endingSoonOffers.isEmpty
              ? _empty()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                      AppSpacing.screen, AppSpacing.screen, 40),
                  itemCount: endingSoonOffers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    return FadeSlideIn(
                      delay: Duration(milliseconds: i < 8 ? i * 45 : 0),
                      child: OfferCard(
                        offer: endingSoonOffers[i],
                        onTap: () => context.push(
                          '/buyer/product',
                          extra: endingSoonOffers[i],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Center(
      child: Column(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedStore01,
            size: 48,
            color: AppColors.borderStrong,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No ending soon deals right now',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  );
}
