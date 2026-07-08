import 'dart:async';

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

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  Timer? _poll;
  String _activeTab = 'All Orders';
  bool _showTip = true;

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
      body: Column(
        children: [
          _buildGreenHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(vendorOrdersProvider.future),
              color: AppColors.primary,
              child: orders.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not load orders: $e')),
                data: (items) => _buildContent(items),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenHeader() {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incoming Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage orders from hotels & restaurants',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {},
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: Colors.white,
                size: 20,
              ),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSlidersHorizontal,
                    color: Colors.white,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  padding: EdgeInsets.zero,
                ),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF23E3E),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Order> items) {
    // Dynamic counts
    final countAll = items.length;
    final countNew = items.where((o) => o.status == OrderStatus.confirmed).length;
    final countAccepted = items.where((o) => o.status == OrderStatus.preparing).length;
    final countPreparing = items.where((o) => o.status == OrderStatus.readyForPickup).length;
    final countCompleted = items.where((o) => o.status == OrderStatus.completed).length;

    // Filter items based on active tab
    final filtered = items.where((o) {
      if (_activeTab == 'New') return o.status == OrderStatus.confirmed;
      if (_activeTab == 'Accepted') return o.status == OrderStatus.preparing;
      if (_activeTab == 'Preparing') return o.status == OrderStatus.readyForPickup;
      if (_activeTab == 'Completed') return o.status == OrderStatus.completed;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildTabsRow(countAll, countNew, countAccepted, countPreparing, countCompleted),
        const SizedBox(height: 16),
        if (_showTip) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _buildTipCard(),
          ),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filtered.length} Orders',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Sort by: ',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Text(
                          'Newest',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textPrimary),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          _empty()
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              children: [
                for (final order in filtered) ...[
                  _OrderCard(order: order),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTabsRow(int all, int newCount, int accepted, int preparing, int completed) {
    final tabs = [
      ('All Orders', all),
      ('New', newCount),
      ('Accepted', accepted),
      ('Preparing', preparing),
      ('Completed', completed),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _activeTab == tab.$1;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.transparent : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    tab.$1,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.textMuted.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${tab.$2}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDFBF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3F2E4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedLeaf02,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respond fast, get higher ratings & repeat orders',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Try to respond within 15 minutes.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showTip = false),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: AppColors.textMuted,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
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
                'No orders here',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Orders matching this status will appear here',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
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
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/seller/order', extra: order),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Hero(
                    tag: 'order-image-${order.id}',
                    child: ProduceImage(
                      imageUrl: order.imagePath,
                      tint: _tint,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Middle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            order.buyerName?.substring(0, 1) ?? 'H',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            order.buyerName ?? 'Grand Hotel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          color: Color(0xFF27AE60),
                          size: 13,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          color: AppColors.textMuted,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Indiranagar, Bengaluru',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.vegetable,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grade A   •   ${order.quantityKg.toInt()} kg',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _urgencyColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _freshnessLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _urgencyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right Status & Cost
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.status.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '5 mins ago',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '₹${order.total.toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: AppColors.textMuted,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          // Actions Row
          _buildActionsRow(context, ref),
        ],
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context, WidgetRef ref) {
    if (order.status == OrderStatus.confirmed) {
      // Confirmed State Actions
      return Row(
        children: [
          TextButton.icon(
            onPressed: () {},
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.textSecondary, size: 14),
            label: const Text(
              'Reject',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  color: Color(0xFF27AE60),
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Respond in 14:48',
                  style: TextStyle(
                    color: Color(0xFF27AE60),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _actionIconBtn(HugeIcons.strokeRoundedMessageMultiple01, Colors.transparent, AppColors.textSecondary, () {}),
          const SizedBox(width: 8),
          _actionIconBtn(
            HugeIcons.strokeRoundedCheckmarkCircle02,
            const Color(0xFF27AE60),
            Colors.white,
            () => _advance(context, ref, OrderStatus.preparing, 'Accepted'),
          ),
        ],
      );
    }

    if (order.status == OrderStatus.preparing) {
      // Accepted State Actions
      return Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2F80ED), size: 16),
          const SizedBox(width: 6),
          const Text(
            'Accepted',
            style: TextStyle(
              color: Color(0xFF2F80ED),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          _actionIconBtn(HugeIcons.strokeRoundedMessageMultiple01, Colors.transparent, AppColors.textSecondary, () {}),
          const SizedBox(width: 8),
          _actionIconBtn(HugeIcons.strokeRoundedCall, Colors.transparent, AppColors.textSecondary, () => _call(context)),
          const SizedBox(width: 8),
          _actionIconBtn(
            HugeIcons.strokeRoundedCheckmarkCircle02,
            const Color(0xFF27AE60),
            Colors.white,
            () => _advance(context, ref, OrderStatus.readyForPickup, 'Preparing'),
          ),
        ],
      );
    }

    if (order.status == OrderStatus.readyForPickup) {
      // Preparing State Actions
      return Row(
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedDeliveryTruck02, color: AppColors.textSecondary, size: 15),
          const SizedBox(width: 6),
          const Text(
            'Pickup today, 12:00 – 2:00 PM',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _actionIconBtn(HugeIcons.strokeRoundedMessageMultiple01, Colors.transparent, AppColors.textSecondary, () {}),
          const SizedBox(width: 8),
          _actionIconBtn(HugeIcons.strokeRoundedCall, Colors.transparent, AppColors.textSecondary, () => _call(context)),
          const SizedBox(width: 8),
          _actionIconBtn(
            HugeIcons.strokeRoundedCheckmarkCircle02,
            const Color(0xFF27AE60),
            Colors.white,
            () => _advance(context, ref, OrderStatus.completed, 'Completed'),
          ),
        ],
      );
    }

    // Completed State Actions
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 16),
        const SizedBox(width: 6),
        const Text(
          'Delivered on 10 May, 10:30 AM',
          style: TextStyle(
            color: Color(0xFF27AE60),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        _actionIconBtn(HugeIcons.strokeRoundedMessageMultiple01, Colors.transparent, AppColors.textSecondary, () {}),
        const SizedBox(width: 8),
        _actionIconBtn(HugeIcons.strokeRoundedInvoice01, const Color(0xFFEDFBF4), const Color(0xFF27AE60), () {}),
      ],
    );
  }

  Widget _actionIconBtn(List<List<dynamic>> icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    final isTransparent = bgColor == Colors.transparent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: isTransparent ? Border.all(color: AppColors.border) : null,
        ),
        alignment: Alignment.center,
        child: HugeIcon(
          icon: icon,
          color: iconColor,
          size: 18,
        ),
      ),
    );
  }

  Future<void> _advance(BuildContext context, WidgetRef ref, OrderStatus target, String label) async {
    try {
      await ref.read(vendorOrdersProvider.notifier).advance(order.id, target);
      if (context.mounted) _toast(context, 'Order updated to $label ✓');
    } catch (e) {
      if (context.mounted) _toast(context, 'Could not update: $e');
    }
  }

  Future<void> _call(BuildContext context) async {
    final uri = Uri.parse('tel:+919000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      _toast(context, 'Could not start the call');
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
