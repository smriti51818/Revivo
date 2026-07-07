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
import '../../core/widgets/section_header.dart';
import 'application/cart_providers.dart';
import 'application/marketplace_providers.dart';
import 'domain/cart_item.dart';
import 'domain/offer.dart';
import 'widgets/bill_summary.dart';
import 'widgets/coupon_sheet.dart';

/// The buyer's cart, Zomato/Blinkit style: the items they added up top, then a
/// strip of more surplus to add, a Revivo coupon, a pickup estimate, and the
/// full bill breakdown with everything they're saving.
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
                        const SectionHeader(title: 'Your rescue'),
                        const SizedBox(height: AppSpacing.sm),
                        for (final item in items) ...[
                          _CartTile(item: item),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _Suggestions(cartIds: {for (final i in items) i.offer.id}),
                        const _CouponCard(),
                        const SizedBox(height: AppSpacing.md),
                        const _PickupEstimate(),
                        const SizedBox(height: AppSpacing.lg),
                        const SectionHeader(title: 'Bill details'),
                        const SizedBox(height: AppSpacing.sm),
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
              if (bill.totalSaved > 0)
                Text('You save ${formatMoney(bill.totalSaved)}',
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

/// One cart line with its live price, struck-out market rate, and a stepper.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 60,
              height: 60,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(offer.vegetable,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ),
                    InkWell(
                      onTap: () => cart.remove(offer.id),
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Text(offer.vendorName,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                FreshnessTicker(
                  expiresAt: offer.expiresAt ??
                      DateTime.now().add(const Duration(hours: 12)),
                  totalHours: offer.totalHours ?? 24,
                  builder: (context, _, _) => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // #2 — struck-out market rate beside the live rescue price.
                      Text('${formatMoney(offer.livePrice())}/kg',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          )),
                      const SizedBox(width: 5),
                      if (offer.liveSavingsPct() > 0)
                        Text(formatMoney(offer.marketPrice),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            )),
                      const Spacer(),
                      Text(formatMoney(item.lineTotal),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _QtyStepper(
                  qty: item.quantityKg,
                  max: offer.availableKg,
                  onChanged: (q) => cart.setQuantity(offer.id, q),
                ),
              ],
            ),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn(Icons.remove, () => onChanged(qty - 1)),
            SizedBox(
              width: 42,
              child: Text(
                formatKg(qty),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            _btn(Icons.add, qty < max ? () => onChanged(qty + 1) : null),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon,
              size: 18,
              color: onTap == null
                  ? AppColors.textMuted
                  : AppColors.primaryDark),
        ),
      );
}

/// "Add more surplus" — offers not already in the cart, most urgent first.
class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.cartIds});
  final Set<String> cartIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider).valueOrNull ?? const <Offer>[];
    final suggestions = offers
        .where((o) => !cartIds.contains(o.id) && !o.isExpired())
        .toList()
      ..sort((a, b) => a.liveSavingsPct().compareTo(b.liveSavingsPct()) * -1);
    final top = suggestions.take(8).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Add more surplus'),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => _SuggestCard(offer: top[i]),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _SuggestCard extends ConsumerWidget {
  const _SuggestCard({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 128,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: () => context.push('/buyer/product', extra: offer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ProduceImage(
                    imageUrl: offer.imageUrl, tint: AppColors.surfaceAlt),
              ),
            ),
            const SizedBox(height: 6),
            Text(offer.vegetable,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700)),
            Text('${formatMoney(offer.livePrice())}/kg',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            const SizedBox(height: 6),
            SizedBox(
              height: 26,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final qty = offer.availableKg >= 1 ? 1.0 : offer.availableKg;
                  ref.read(cartProvider.notifier).add(offer, qty);
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('+ ADD',
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apply / show a Revivo coupon.
class _CouponCard extends ConsumerWidget {
  const _CouponCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applied = ref.watch(appliedCouponProvider);
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => showCouponSheet(context, ref),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.local_offer_outlined,
              color: AppColors.primary, size: 20),
        ),
        title: Text(
          applied == null ? 'Apply a coupon' : 'Coupon ${applied.code} applied',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          applied == null
              ? 'Save more on this rescue with Revivo offers'
              : applied.title,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: applied == null
            ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
            : TextButton(
                onPressed: () =>
                    ref.read(appliedCouponProvider.notifier).clear(),
                child: const Text('Remove',
                    style: TextStyle(color: AppColors.danger)),
              ),
      ),
    );
  }
}

/// Self-pickup ETA + a note that the exact slot is chosen at checkout.
class _PickupEstimate extends StatelessWidget {
  const _PickupEstimate();

  @override
  Widget build(BuildContext context) {
    final ready = DateTime.now().add(const Duration(minutes: 20));
    final h = ready.hour % 12 == 0 ? 12 : ready.hour % 12;
    final m = ready.minute.toString().padLeft(2, '0');
    final ap = ready.hour < 12 ? 'AM' : 'PM';
    return AppCard(
      color: AppColors.surfaceAlt,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.directions_walk_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready for pickup by ~$h:$m $ap',
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Self-pickup · schedule your exact slot at checkout',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
