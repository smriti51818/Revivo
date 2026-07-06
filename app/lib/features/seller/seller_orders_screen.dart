import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/band_chip.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';
import '../buyer/domain/order.dart';
import 'application/vendor_orders_providers.dart';

/// Seller's incoming orders — real orders hotels placed against this seller's
/// surplus. First-come-first-serve: stock is reserved when the order is placed
/// (no manual approval), then it auto-advances through fulfilment. Polls so the
/// status updates show up live.
class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.read(vendorOrdersProvider.notifier).reload();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(vendorOrdersProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(vendorOrdersProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              const Text(
                'Incoming orders',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Live orders from hotels & kitchens — first come, first served',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                data: (items) => _content(items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(List<Order> items) {
    if (items.isEmpty) return _empty();
    final active =
        items.where((o) => o.status != OrderStatus.completed).toList();
    final done =
        items.where((o) => o.status == OrderStatus.completed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'To fulfil (${active.length})'),
        const SizedBox(height: AppSpacing.md),
        if (active.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text('No orders to fulfil right now.',
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          for (final o in active) ...[
            _OrderCard(order: o),
            const SizedBox(height: AppSpacing.md),
          ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const SectionHeader(title: 'Completed'),
          const SizedBox(height: AppSpacing.md),
          for (final o in done) ...[
            _OrderCard(order: o),
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
                'When a hotel orders your surplus, it shows up here',
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
                      order.buyerName ?? 'Buyer',
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.vegetable,
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
              BandChip(band: order.band),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(order.total),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${formatKg(order.quantityKg)} · ${formatMoney(order.pricePerKg)}/kg',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
