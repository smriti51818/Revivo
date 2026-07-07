import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_chip.dart';
import 'application/marketplace_providers.dart';
import 'domain/order.dart';

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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(ordersProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              const Text(
                'My orders',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Track your surplus rescues',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              orders.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(child: Text('Could not load orders: $e')),
                ),
                data: (items) {
                  if (items.isEmpty) return _empty();
                  return Column(
                    children: [
                      for (final order in items) ...[
                        _OrderCard(order: order),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 40, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No orders yet',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
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
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  ChipTone get _tone => switch (order.status) {
        OrderStatus.confirmed => ChipTone.info,
        OrderStatus.preparing => ChipTone.warning,
        OrderStatus.readyForPickup => ChipTone.success,
        OrderStatus.completed => ChipTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/buyer/track', extra: order),
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
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.vendorName,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
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
              const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                order.pickupSlot.isEmpty
                    ? 'Pickup anytime today'
                    : 'Pickup · ${order.pickupSlot}',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted),
              ),
              const Spacer(),
              const Text('Track',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.primary),
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
