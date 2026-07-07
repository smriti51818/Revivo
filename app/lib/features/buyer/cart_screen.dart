import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/freshness_countdown.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/produce_image.dart';
import 'application/cart_providers.dart';
import 'domain/cart_item.dart';
import 'widgets/bill_summary.dart';

/// The buyer's cart: surplus lines grouped by vendor, each with a live price
/// and countdown, plus the running bill and a path to checkout.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final bill = ref.watch(cartBillProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: SafeArea(
        child: items.isEmpty
            ? _empty(context)
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      children: [
                        for (final entry in _byVendor(items).entries) ...[
                          _vendorHeader(entry.key),
                          const SizedBox(height: AppSpacing.sm),
                          for (final item in entry.value) ...[
                            _CartTile(item: item),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          const SizedBox(height: AppSpacing.md),
                        ],
                        const _PickupNote(),
                        const SizedBox(height: AppSpacing.md),
                        BillSummary(bill: bill),
                      ],
                    ),
                  ),
                  _checkoutBar(context, bill),
                ],
              ),
      ),
    );
  }

  Map<String, List<CartItem>> _byVendor(List<CartItem> items) {
    final map = <String, List<CartItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.offer.vendorName, () => []).add(item);
    }
    return map;
  }

  Widget _vendorHeader(String vendor) => Row(
        children: [
          const Icon(Icons.storefront_outlined,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            vendor,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );

  Widget _checkoutBar(BuildContext context, CartBill bill) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatMoney(bill.total),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              if (bill.saved > 0)
                Text('You save ${formatMoney(bill.saved)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: PrimaryButton(
              label: 'Checkout',
              icon: Icons.arrow_forward,
              onPressed: () => context.push('/buyer/checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 44, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            const Text('Your cart is empty',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            const Text('Rescue some surplus before its window closes',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => context.go('/buyer/home'),
              child: const Text('Browse the market'),
            ),
          ],
        ),
      );
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    final offer = item.offer;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 56,
              height: 56,
              child: ProduceImage(
                imageUrl: offer.imageUrl,
                tint: AppColors.surfaceAlt,
                iconSize: 26,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.vegetable,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                FreshnessTicker(
                  expiresAt: offer.expiresAt ??
                      DateTime.now().add(const Duration(hours: 12)),
                  totalHours: offer.totalHours ?? 24,
                  builder: (context, _, _) => Text(
                    '${formatMoney(offer.livePrice())}/kg · ${formatMoney(item.lineTotal)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _QtyStepper(
            qty: item.quantityKg,
            max: offer.availableKg,
            onChanged: (q) => cart.setQuantity(offer.id, q),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.max,
    required this.onChanged,
  });

  final double qty;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () => onChanged(qty - 1)),
          SizedBox(
            width: 34,
            child: Text(
              qty == qty.roundToDouble()
                  ? qty.toStringAsFixed(0)
                  : qty.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          _btn(Icons.add, qty < max ? () => onChanged(qty + 1) : null),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 34,
          height: 36,
          child: Icon(icon,
              size: 18,
              color: onTap == null
                  ? AppColors.textMuted
                  : AppColors.primaryDark),
        ),
      );
}

class _PickupNote extends StatelessWidget {
  const _PickupNote();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceAlt,
      child: Row(
        children: [
          const Icon(Icons.directions_walk_rounded,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Self-pickup from the vendor — you\'ll pick a time slot next.',
              style:
                  TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
