import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/band_chip.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';
import 'application/marketplace_providers.dart';
import 'domain/order.dart';
import 'widgets/impact_receipt.dart';
import 'widgets/rate_order_sheet.dart';

/// The full post-order view (Blinkit style): bought-from, timing, the money
/// saved, delivery details, a rate-your-experience block, an "arrived
/// correctly?" check, and the order summary.
class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  Timer? _poll;
  bool? _arrivedOk;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.read(ordersProvider.notifier).reload();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Order get _order {
    final live = ref.watch(ordersProvider).valueOrNull;
    return live?.firstWhere(
          (o) => o.id == widget.order.id,
          orElse: () => widget.order,
        ) ??
        widget.order;
  }

  ChipTone get _tone => switch (_order.status) {
    OrderStatus.confirmed => ChipTone.info,
    OrderStatus.preparing => ChipTone.warning,
    OrderStatus.readyForPickup => ChipTone.success,
    OrderStatus.completed => ChipTone.neutral,
  };

  Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not open that')));
    }
  }

  void _callVendor() {
    // In a real app, we'd use the vendor's actual phone number
    final uri = Uri.parse('tel:+919876543210');
    _open(uri);
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final done = order.status == OrderStatus.completed;

    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            _statusHeader(order),
            const SizedBox(height: AppSpacing.lg),
            _boughtFrom(order),
            const SizedBox(height: AppSpacing.lg),
            _summary(order),
            const SizedBox(height: AppSpacing.lg),
            _delivery(order),
            if (done) ...[
              const SizedBox(height: AppSpacing.lg),
              ImpactReceipt(order: order),
              const SizedBox(height: AppSpacing.lg),
              _arrivedCheck(),
              const SizedBox(height: AppSpacing.lg),
              _rating(order),
            ] else ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Track this order',
                onPressed: () => context.push('/buyer/track', extra: order),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusHeader(Order order) {
    final done = order.status == OrderStatus.completed;
    return AppCard(
      color: done ? Colors.white : const Color(0xFFF2FBF6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: done ? AppColors.primarySurface : AppColors.infoSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: HugeIcon(
              icon: done
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : HugeIcons.strokeRoundedDeliveryTruck02,
              color: done ? AppColors.primary : AppColors.info,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.vegetable} · ${formatKg(order.quantityKg)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Order #${_shortId(order.id)}',
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
    );
  }

  Widget _boughtFrom(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Bought from'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () =>
                    context.push('/buyer/vendor', extra: order.vendorName),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedStore01,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.vendorName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    BandChip(band: order.band),
                  ],
                ),
              ),
              const Divider(height: AppSpacing.xl),
              _detailRow(
                HugeIcons.strokeRoundedCalendar01,
                'Ordered',
                formatDateTime(order.placedAt),
              ),
              const SizedBox(height: 10),
              _detailRow(
                HugeIcons.strokeRoundedClock01,
                'Placed',
                formatAgo(order.placedAt),
              ),
              const SizedBox(height: 10),
              _detailRow(
                HugeIcons.strokeRoundedLeaf02,
                'Freshness when bought',
                '${order.band.label} · ${order.band.meaning.toLowerCase()}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summary(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Order summary'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order.vegetable} · ${formatKg(order.quantityKg)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${formatKg(order.quantityKg)} × ${formatMoney(order.pricePerKg)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              _billRow('Item total', formatMoney(order.total)),
              if (order.saved > 0) ...[
                const SizedBox(height: 8),
                _billRow(
                  'Rescue saving vs market',
                  '− ${formatMoney(order.saved)}',
                  highlight: true,
                ),
              ],
              const SizedBox(height: 8),
              _billRow(
                'Payment',
                '${_payLabel(order.paymentMethod)} · ${order.paymentStatus.label}',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(height: 1),
              ),
              _billRow('Total paid', formatMoney(order.total), bold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _delivery(Order order) {
    final mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${order.vendorName}, Coimbatore')}',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Delivery details'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(
                HugeIcons.strokeRoundedWalking,
                'Method',
                'Self-pickup from vendor',
              ),
              const SizedBox(height: 10),
              _detailRow(
                HugeIcons.strokeRoundedClock01,
                'Pickup slot',
                order.pickupSlot.isEmpty ? 'Anytime today' : order.pickupSlot,
              ),
              const SizedBox(height: 10),
              _detailRow(
                HugeIcons.strokeRoundedLocation01,
                'Address',
                '${order.vendorName}, Coimbatore',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(mapsUri),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDirections01,
                        size: 18,
                      ),
                      label: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _callVendor,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCall,
                        size: 18,
                      ),
                      label: const Text('Call vendor'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _arrivedCheck() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Did your items arrive correctly?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text(
            'Confirm the surplus matched what you rescued',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_arrivedOk == null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _arrivedOk = true),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      size: 18,
                    ),
                    label: const Text('Yes, all good'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _arrivedOk = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert01,
                      size: 18,
                    ),
                    label: const Text('Report issue'),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _arrivedOk!
                    ? AppColors.primarySurface
                    : AppColors.warningSurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: _arrivedOk!
                        ? HugeIcons.strokeRoundedCheckmarkBadge01
                        : HugeIcons.strokeRoundedCustomerSupport,
                    size: 18,
                    color: _arrivedOk! ? AppColors.primary : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _arrivedOk!
                          ? 'Thanks for confirming — it counts toward the vendor\'s trust score.'
                          : 'We\'ve logged this. Our team will follow up on the mismatch.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _rating(Order order) {
    if (order.isRated) {
      return AppCard(
        child: Row(
          children: [
            const Text(
              'Your rating',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            for (var i = 1; i <= 5; i++)
              HugeIcon(
                icon: HugeIcons.strokeRoundedStar,
                size: 18,
                color: i <= order.rating!
                    ? AppColors.warning
                    : AppColors.border,
              ),
          ],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate your experience',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text(
            'Your feedback builds the vendor\'s trust score',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Rate this rescue',
            onPressed: () => showRateOrderSheet(context, ref, order),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(dynamic icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(icon: icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label  ',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _billRow(
    String label,
    String value, {
    bool highlight = false,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 13.5,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _payLabel(String m) => switch (m.toUpperCase()) {
    'UPI' => 'UPI',
    'CARD' => 'Card',
    'WALLET' => 'Revivo Wallet',
    _ => 'Pay on pickup',
  };

  String _shortId(String id) {
    final cleaned = id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return cleaned.length <= 6
        ? cleaned.toUpperCase()
        : cleaned.substring(cleaned.length - 6).toUpperCase();
  }
}
