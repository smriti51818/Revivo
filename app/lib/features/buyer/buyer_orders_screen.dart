import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';
import 'application/failed_payments_providers.dart';
import 'application/favorites_providers.dart';
import 'application/marketplace_providers.dart';
import 'domain/failed_payment.dart';
import 'domain/offer.dart';
import 'domain/order.dart';
import 'widgets/favorite_heart.dart';

class BuyerOrdersScreen extends ConsumerStatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  ConsumerState<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends ConsumerState<BuyerOrdersScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Poll so the Step Functions lifecycle updates show up live.
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.read(ordersProvider.notifier).reload();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final offers = ref.watch(offersProvider);
    final failed = ref.watch(failedPaymentsProvider);
    final favIds = ref.watch(favoritesProvider);

    final savedOffers = offers.whenData((all) =>
        all.where((o) => favIds.contains(o.id)).toList());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildGreenHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(ordersProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                    AppSpacing.screen, AppSpacing.screen, 40),
                children: [
                  if (failed.isNotEmpty) ...[
                    _FailedSection(payments: failed),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  orders.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(child: Text('Could not load orders: $e')),
                    ),
                    data: (items) =>
                        _orders(items, hasFailed: failed.isNotEmpty),
                  ),
                  savedOffers.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (saved) => saved.isEmpty
                        ? const SizedBox.shrink()
                        : _savedSection(saved),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'My orders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 48),
            child: Text(
              'Track your surplus rescues',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orders(List<Order> items, {required bool hasFailed}) {
    if (items.isEmpty) return hasFailed ? const SizedBox.shrink() : _empty();
    final active = items
        .where((o) => o.status != OrderStatus.completed)
        .toList();
    final completed = items
        .where((o) => o.status == OrderStatus.completed)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (active.isNotEmpty) ...[
          const SectionHeader(title: 'Active'),
          const SizedBox(height: AppSpacing.sm),
          for (final order in active) ...[
            _OrderCard(order: order),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (completed.isNotEmpty) ...[
          if (active.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          const SectionHeader(title: 'Completed'),
          const SizedBox(height: AppSpacing.sm),
          for (final order in completed) ...[
            _OrderCard(order: order),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ],
    );
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.only(top: 64),
    child: Center(
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInvoice01,
            size: 40,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Browse the market to rescue surplus produce',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );

  Widget _savedSection(List<Offer> saved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedFavourite,
              size: 18,
              color: Color(0xFFE11D48),
            ),
            const SizedBox(width: 6),
            Text(
              'Saved · ${saved.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final offer in saved) ...[
          _SavedCard(offer: offer),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// The "Payment failed" section — checkout attempts that never completed.
class _FailedSection extends ConsumerWidget {
  const _FailedSection({required this.payments});
  final List<FailedPayment> payments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedAlert01,
              size: 18,
              color: AppColors.danger,
            ),
            const SizedBox(width: 6),
            Text(
              'Payment failed · ${payments.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final p in payments) ...[
          _FailedCard(payment: p),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _FailedCard extends ConsumerWidget {
  const _FailedCard({required this.payment});
  final FailedPayment payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = payment.lines.isEmpty ? null : payment.lines.first;
    final extra = payment.itemCount - 1;
    final summary = first == null
        ? '${payment.itemCount} items'
        : '${first.vegetable}${extra > 0 ? ' + $extra more' : ''}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${payment.reason} · ${formatAgo(payment.attemptedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(payment.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(failedPaymentsProvider.notifier)
                        .remove(payment.id);
                    context.push('/buyer/cart');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedRefresh01,
                    size: 18,
                  ),
                  label: const Text('Retry payment'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => ref
                    .read(failedPaymentsProvider.notifier)
                    .remove(payment.id),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = offer.liveSavingsPct();
    return AppCard(
      onTap: () => context.push('/buyer/product', extra: offer),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.vegetable,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${offer.vendorName} · ${offer.availableKg.toStringAsFixed(1)} kg left',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      formatMoney(offer.livePrice()),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text('/kg', style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                    if (saving > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$saving% off',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          FavoriteHeart(offerId: offer.id, onSurface: false),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  ChipTone get _tone => switch (order.status) {
    OrderStatus.confirmed => ChipTone.info,
    OrderStatus.preparing => ChipTone.warning,
    OrderStatus.readyForPickup => ChipTone.success,
    OrderStatus.completed => ChipTone.done,
  };

  @override
  Widget build(BuildContext context) {
    final done = order.status == OrderStatus.completed;
    return AppCard(
      color: done ? Colors.white : const Color(0xFFF2FBF6),
      onTap: () => context.push('/buyer/order', extra: order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.vegetable,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.vendorName} · ${formatAgo(order.placedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: order.status.label, tone: _tone),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              _meta('Quantity', formatKg(order.quantityKg)),
              const SizedBox(width: AppSpacing.xl),
              _meta('Total', formatMoney(order.total)),
              const Spacer(),
              if (order.saved > 0)
                _meta('Saved', formatMoney(order.saved), highlight: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                order.pickupSlot.isEmpty
                    ? 'Pickup anytime today'
                    : 'Pickup · ${order.pickupSlot}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (order.status != OrderStatus.completed)
                TextButton.icon(
                  onPressed: () => context.push('/buyer/track', extra: order),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Track Order',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else ...[
                const Text(
                  'View details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
