import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/format.dart';
import '../../core/models/freshness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/produce_image.dart';
import '../buyer/domain/order.dart';
import 'application/vendor_orders_providers.dart';

class SellerOrderDetailsScreen extends ConsumerWidget {
  const SellerOrderDetailsScreen({super.key, required this.order});
  final Order order;

  Color get _statusColor => switch (order.status) {
        OrderStatus.confirmed => const Color(0xFF27AE60),
        OrderStatus.preparing => const Color(0xFF2F80ED),
        OrderStatus.readyForPickup => const Color(0xFFF2994A),
        OrderStatus.completed => const Color(0xFF2196F3),
      };

  Color get _tint => switch (order.band) {
        FreshnessBand.good => AppColors.successSurface,
        FreshnessBand.useSoon => AppColors.warningSurface,
        FreshnessBand.rescue => AppColors.dangerSurface,
      };

  Color get _urgencyColor => switch (order.band) {
        FreshnessBand.rescue => const Color(0xFFF23E3E),
        FreshnessBand.useSoon => const Color(0xFFF2994A),
        FreshnessBand.good => const Color(0xFF27AE60),
      };

  String get _freshnessLabel => switch (order.band) {
        FreshnessBand.rescue => 'Rescue (0-6h)',
        FreshnessBand.useSoon => 'Use soon (6-12h)',
        FreshnessBand.good => order.marketPricePerKg - order.pricePerKg > 15
            ? 'Best price (12-24h)'
            : 'Fresh (24h+)',
      };

  /// Quality grade derived from the freshness band — Good → A+, Use soon → A,
  /// Rescue → B. There is no separate grade field on the order.
  String get _grade => switch (order.band) {
        FreshnessBand.good => 'Grade A+',
        FreshnessBand.useSoon => 'Grade A',
        FreshnessBand.rescue => 'Grade B',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveOrders = ref.watch(vendorOrdersProvider).valueOrNull ?? [];
    final currentOrder = liveOrders.firstWhere((o) => o.id == order.id, orElse: () => order);

    return Scaffold(
      body: Column(
        children: [
          _buildGreenHeader(context, currentOrder),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                _buildHotelInfoCard(currentOrder),
                const SizedBox(height: 12),
                _buildCountdownBanner(currentOrder),
                const SizedBox(height: 16),
                _buildItemsCard(currentOrder),
                const SizedBox(height: 16),
                _buildPricingDetailsCard(currentOrder),
                const SizedBox(height: 16),
                _buildOrderInformationCard(currentOrder),
                if (currentOrder.isRated) ...[
                  const SizedBox(height: 16),
                  _buildReviewCard(currentOrder),
                ],
                const SizedBox(height: 20),
                _buildRespondSection(context, ref, currentOrder),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenHeader(BuildContext context, Order currentOrder) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Colors.white,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Order ID #RV${currentOrder.id.substring(0, 5).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _call(context),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCall,
                color: Colors.white,
                size: 20,
              ),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelInfoCard(Order currentOrder) {
    final orderNo = currentOrder.id.length >= 5
        ? currentOrder.id.substring(currentOrder.id.length - 5).toUpperCase()
        : currentOrder.id.toUpperCase();
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: avatar + name/order (flexible) + status pill — long hotel
          // names ellipsis inside the Expanded and never break the layout.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (currentOrder.buyerName?.trim().isNotEmpty ?? false)
                      ? currentOrder.buyerName!.trim()[0].toUpperCase()
                      : 'H',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            currentOrder.buyerName ?? 'Buyer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Buyer-type glyph (a store, not a tick) — signals this
                        // is a verified business buyer without the check clutter.
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedStore01,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #$orderNo',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  currentOrder.status.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          // Row 2: freshness chip + placed timing.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _tint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _freshnessLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _urgencyColor,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Placed ${formatAgo(currentOrder.placedAt)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(currentOrder.placedAt),
                    style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBanner(Order currentOrder) {
    if (currentOrder.status != OrderStatus.confirmed) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDFBF4),
        border: Border.all(color: const Color(0xFFD3F2E4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedClock01,
            color: Color(0xFF27AE60),
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            'New order · placed ${formatAgo(currentOrder.placedAt)}',
            style: const TextStyle(
              color: Color(0xFF27AE60),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(Order currentOrder) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items (1)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ProduceImage(
                    imageUrl: currentOrder.imagePath,
                    tint: _tint,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentOrder.vegetable,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_grade   •   ${currentOrder.band.label}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${currentOrder.quantityKg.toInt()} kg   x   ₹${currentOrder.pricePerKg.toInt()}/kg',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${currentOrder.total.toInt()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingDetailsCard(Order currentOrder) {
    final itemTotal = currentOrder.total;
    final fee = itemTotal * 0.05;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _priceRow('Item Total', '₹${itemTotal.toInt()}'),
          const SizedBox(height: 8),
          _priceRow('Platform Fee (5%)', '₹${fee.toStringAsFixed(2)}'),
          const Divider(height: 24, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 4),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    color: AppColors.textMuted,
                    size: 13,
                  ),
                ],
              ),
              Text(
                '₹${itemTotal.toInt()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27AE60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
        Text(
          val,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildOrderInformationCard(Order currentOrder) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(HugeIcons.strokeRoundedInvoice01, 'Order ID', '#RV${currentOrder.id.substring(0, 5).toUpperCase()}'),
          if (currentOrder.buyerName != null)
            _infoRow(HugeIcons.strokeRoundedUserCircle, 'Buyer', currentOrder.buyerName!),
          _infoRow(HugeIcons.strokeRoundedCalendar01, 'Placed', formatDateTime(currentOrder.placedAt)),
          _infoRow(
            HugeIcons.strokeRoundedClock01,
            'Preferred Pickup',
            currentOrder.pickupSlot.isEmpty ? 'Anytime today' : currentOrder.pickupSlot,
          ),
          _infoRow(HugeIcons.strokeRoundedMoney01, 'Payment', currentOrder.paymentStatus.label),
        ],
      ),
    );
  }

  Widget _infoRow(List<List<dynamic>> icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: AppColors.textMuted, size: 15),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Order o) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Buyer review',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              for (var i = 1; i <= 5; i++)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedStar,
                  size: 16,
                  color: i <= (o.rating ?? 0)
                      ? const Color(0xFFF2994A)
                      : AppColors.border,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${o.buyerName ?? 'Buyer'} · ${o.rating}/5',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          if (o.ratingTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in o.ratingTags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(t,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark)),
                  ),
              ],
            ),
          ],
          if (o.ratingComment.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('"${o.ratingComment}"',
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildRespondSection(BuildContext context, WidgetRef ref, Order currentOrder) {
    if (currentOrder.status == OrderStatus.confirmed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Respond to this Order',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReject(context, ref, currentOrder),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF2D3D3)),
                    backgroundColor: const Color(0xFFFFF5F5),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: Color(0xFFF23E3E), size: 16),
                  label: const Text('Reject', style: TextStyle(color: Color(0xFFF23E3E), fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _advance(context, ref, currentOrder, OrderStatus.preparing, 'Accepted'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, color: Colors.white, size: 16),
                  label: const Text('Accept Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (currentOrder.status == OrderStatus.preparing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [

              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _advance(context, ref, currentOrder, OrderStatus.readyForPickup, 'Preparing'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, color: Colors.white, size: 16),
                  label: const Text('Mark Ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (currentOrder.status == OrderStatus.readyForPickup) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Handover Verification',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [

              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _advance(context, ref, currentOrder, OrderStatus.completed, 'Completed'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, color: Colors.white, size: 16),
                  label: const Text('Handover Package', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDFBF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, color: Color(0xFF27AE60), size: 18),
          SizedBox(width: 8),
          Text(
            'Order Delivered & Completed Successfully',
            style: TextStyle(
              color: Color(0xFF27AE60),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReject(
      BuildContext context, WidgetRef ref, Order currentOrder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline this order?'),
        content: Text(
          'Decline ${currentOrder.buyerName ?? 'this buyer'}\'s order for '
          '${currentOrder.vegetable}? It will be removed from your queue.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF23E3E)),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(vendorOrdersProvider.notifier).reject(currentOrder.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Order declined')));
      context.pop();
    }
  }

  Future<void> _advance(BuildContext context, WidgetRef ref, Order currentOrder, OrderStatus target, String label) async {
    try {
      await ref.read(vendorOrdersProvider.notifier).advance(currentOrder.id, target);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Order updated to $label 🎉')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Could not update: $e')));
      }
    }
  }

  void _call(BuildContext context) async {
    final uri = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Could not open dialer')));
    }
  }
}
