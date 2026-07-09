import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import 'application/marketplace_providers.dart';
import 'domain/order.dart';
import 'widgets/impact_receipt.dart';
import 'widgets/rate_order_sheet.dart';

/// The four visible stages a self-pickup order moves through.
const _steps = <({String title, String sub})>[
  (title: 'Order placed', sub: 'The vendor has your request'),
  (title: 'Vendor preparing', sub: 'Your surplus is being set aside'),
  (title: 'Ready for pickup', sub: 'Collect it within your slot'),
  (title: 'Completed', sub: 'Picked up — thank you for rescuing it'),
];

int _statusIndex(OrderStatus s) => switch (s) {
  OrderStatus.confirmed => 0,
  OrderStatus.preparing => 1,
  OrderStatus.readyForPickup => 2,
  OrderStatus.completed => 3,
};

/// Live tracking for a single order: a status timeline that advances with the
/// Step Functions lifecycle, plus pickup + bill details.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _poll;

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

  /// Prefer the freshest copy from the polled list; fall back to the one we
  /// were handed so the screen still renders before the first poll returns.
  Order get _order {
    final live = ref.watch(ordersProvider).valueOrNull;
    return live?.firstWhere(
          (o) => o.id == widget.order.id,
          orElse: () => widget.order,
        ) ??
        widget.order;
  }

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
    final current = _statusIndex(order.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildGreenHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                _headline(order),
                const SizedBox(height: AppSpacing.xl),
                _timeline(current),
                if (order.status == OrderStatus.completed) ...[
                  const SizedBox(height: AppSpacing.xl),
                  ImpactReceipt(order: order),
                  const SizedBox(height: AppSpacing.lg),
                  _ratingSection(order),
                ],
                const SizedBox(height: AppSpacing.xl),
                _pickupCard(order),
                const SizedBox(height: AppSpacing.lg),
                _billCard(order),
              ],
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
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Track order',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headline(Order order) {
    final done = order.status == OrderStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stylised pickup map (schematic grid — no external tiles/key needed).
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDeliveryTruck01,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        switch (order.status) {
                          OrderStatus.confirmed => 'Order confirmed',
                          OrderStatus.preparing => 'Being prepared',
                          OrderStatus.readyForPickup => 'Ready for pickup',
                          OrderStatus.completed => 'Picked up',
                        },
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: done ? AppColors.primarySurface : AppColors.infoSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.vendorName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timeline(int current) {
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            _TimelineRow(
              title: _steps[i].title,
              sub: _steps[i].sub,
              state: i < current
                  ? _StepState.done
                  : i == current
                  ? _StepState.active
                  : _StepState.todo,
              isLast: i == _steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _ratingSection(Order order) {
    if (order.isRated) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Your rating',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                for (var i = 1; i <= 5; i++)
                  HugeIcon(
                    icon: i <= order.rating!
                        ? HugeIcons.strokeRoundedStar
                        : HugeIcons.strokeRoundedStar,
                    size: 18,
                    color: i <= order.rating!
                        ? AppColors.warning
                        : AppColors.border,
                  ),
              ],
            ),
            if (order.ratingTags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in order.ratingTags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How was this rescue?',
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

  Widget _pickupCard(Order order) {
    final mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${order.vendorName}, Coimbatore')}',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Pickup'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.pickupSlot.isEmpty
                        ? 'Anytime today'
                        : 'Slot · ${order.pickupSlot}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order.vendorName} · Coimbatore',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.status != OrderStatus.completed) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedKey01,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Show this code at pickup',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      Text(
                        order.handoverCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _billCard(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Bill'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              _row(
                '${formatKg(order.quantityKg)} × ${formatMoney(order.pricePerKg)}/kg',
                formatMoney(order.total),
              ),
              if (order.saved > 0) ...[
                const SizedBox(height: 8),
                _row(
                  'Saved vs market',
                  '− ${formatMoney(order.saved)}',
                  highlight: true,
                ),
              ],
              const SizedBox(height: 8),
              _row('Payment', _payLabel(order.paymentMethod)),
            ],
          ),
        ),
      ],
    );
  }

  String _payLabel(String m) => switch (m) {
    'UPI' => 'UPI',
    'CARD' => 'Card',
    'WALLET' => 'Revivo Wallet',
    _ => 'Pay on pickup',
  };

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

enum _StepState { done, active, todo }

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.sub,
    required this.state,
    required this.isLast,
  });

  final String title;
  final String sub;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final active = state != _StepState.todo;
    final color = active ? AppColors.primary : AppColors.borderStrong;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: state == _StepState.done
                      ? AppColors.primary
                      : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: state == _StepState.done
                    ? const HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        size: 14,
                        color: Colors.white,
                      )
                    : state == _StepState.active
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: state == _StepState.done
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
