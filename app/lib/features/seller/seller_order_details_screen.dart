import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
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
                const SizedBox(height: 20),
                _buildRespondSection(context, ref, currentOrder),
                const SizedBox(height: 16),
                _buildSalesTipBanner(),
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
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentOrder.status.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _freshnessLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _urgencyColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              currentOrder.buyerName?.substring(0, 1) ?? 'H',
              style: const TextStyle(
                fontSize: 14,
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
                        currentOrder.buyerName ?? 'Grand Hotel',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      color: Color(0xFF27AE60),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Indiranagar, Bengaluru',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Placed',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              const Text(
                '5 mins ago',
                style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '10 May, 9:36 AM',
                style: TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedClock01,
            color: Color(0xFF27AE60),
            size: 15,
          ),
          SizedBox(width: 6),
          Text(
            'Respond within 14:48',
            style: TextStyle(
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
                    const Text(
                      'Grade A   •   Fresh',
                      style: TextStyle(
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
          _infoRow(HugeIcons.strokeRoundedStore01, 'Business Type', 'Hotel'),
          _infoRow(HugeIcons.strokeRoundedClock01, 'Preferred Pickup', 'Today, 12:00 – 2:00 PM'),
          _infoRow(HugeIcons.strokeRoundedUserCircle, 'Contact Person', 'Rahul Sharma'),
          _infoRow(HugeIcons.strokeRoundedCall, 'Phone Number', '+91 98765 43210'),
          _infoRow(HugeIcons.strokeRoundedNote01, 'Additional Note', 'Please ensure fresh and firm tomatoes.'),
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
                  onPressed: () {},
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

  Widget _buildSalesTipBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDFBF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3F2E4)),
      ),
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedLeaf02,
            color: Color(0xFF27AE60),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fast Response, More Sales!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Respond within 15 mins to get higher ratings and repeat orders.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            color: AppColors.textMuted,
            size: 16,
          ),
        ],
      ),
    );
  }

  Future<void> _advance(BuildContext context, WidgetRef ref, Order currentOrder, OrderStatus target, String label) async {
    try {
      await ref.read(vendorOrdersProvider.notifier).advance(currentOrder.id, target);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Order updated to $label ✓')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Could not update: $e')));
      }
    }
  }

  Future<void> _call(BuildContext context) async {
    final uri = Uri.parse('tel:+919000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not start call')));
    }
  }
}
