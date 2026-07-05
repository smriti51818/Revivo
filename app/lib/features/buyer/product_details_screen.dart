import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/freshness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/band_chip.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/produce_image.dart';
import 'application/marketplace_providers.dart';
import 'domain/offer.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.offer});

  final Offer offer;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  late double _qty = widget.offer.availableKg >= 5 ? 5 : 1;
  bool _placing = false;

  Offer get offer => widget.offer;

  Color get _tint => switch (offer.band) {
        FreshnessBand.good => AppColors.successSurface,
        FreshnessBand.useSoon => AppColors.warningSurface,
        FreshnessBand.rescue => AppColors.dangerSurface,
      };

  void _stepQty(double delta) {
    final next = (_qty + delta).clamp(1, offer.availableKg).toDouble();
    setState(() => _qty = next);
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      final order = await ref
          .read(ordersProvider.notifier)
          .placeOrder(offer: offer, quantityKg: _qty);
      if (!mounted) return;
      context.go('/buyer/order-confirmed', extra: order);
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not place order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _qty * offer.offerPrice;
    final saved = _qty * offer.savingsPerKg;

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ProduceImage(
                        imageUrl: offer.imageUrl,
                        tint: _tint,
                        iconSize: 64,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: BandChip(
                          band: offer.band, timeRange: offer.timeRange),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  offer.vendorName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (offer.distanceKm > 0) ...[
                  const Icon(Icons.place_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    '${offer.distanceKm.toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              offer.vegetable,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatMoney(offer.offerPrice)} / kg',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (offer.savingsPct > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      formatMoney(offer.marketPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                const Spacer(),
                if (offer.savingsPct > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${offer.savingsPct}% below market',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _freshnessCard(),
            const SizedBox(height: AppSpacing.lg),
            _quantityCard(),
            const SizedBox(height: AppSpacing.lg),
            _summaryRow('Subtotal', formatMoney(total)),
            const SizedBox(height: 6),
            if (saved > 0)
              _summaryRow('You save vs market', formatMoney(saved),
                  highlight: true),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Place order · ${formatMoney(total)}',
              icon: Icons.shopping_bag_outlined,
              loading: _placing,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _freshnessCard() {
    return AppCard(
      color: AppColors.surfaceAlt,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best used within ${offer.timeRange}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  offer.band.meaning,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityCard() {
    return AppCard(
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quantity',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${formatKg(offer.availableKg)} available',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const Spacer(),
          _stepBtn(Icons.remove, () => _stepQty(-1),
              enabled: _qty > 1),
          SizedBox(
            width: 56,
            child: Text(
              formatKg(_qty),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          _stepBtn(Icons.add, () => _stepQty(1),
              enabled: _qty < offer.availableKg),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, {required bool enabled}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySurface : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled ? AppColors.primaryDark : AppColors.textMuted),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
