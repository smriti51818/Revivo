import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../buyer/domain/order.dart';
import '../notifications/widgets/notification_bell.dart';
import 'application/listings_providers.dart';
import 'application/vendor_orders_providers.dart';
import 'domain/listing.dart';
import 'widgets/listing_card.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(listingsProvider);
    final orders = ref.watch(vendorOrdersProvider).valueOrNull ?? const <Order>[];
    final name = ref.watch(sessionProvider)?.name ?? 'Vendor';

    final now = DateTime.now();
    final todayKg = orders
        .where((o) =>
            o.placedAt.year == now.year &&
            o.placedAt.month == now.month &&
            o.placedAt.day == now.day)
        .fold<double>(0, (sum, o) => sum + o.quantityKg);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/seller/add'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(vendorOrdersProvider.notifier).reload();
            ref.invalidate(listingsProvider);
            await ref.read(listingsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              _Header(name: name),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Total listings',
                      value: '${listings.valueOrNull?.length ?? 0}',
                      badge: '+ live',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      label: 'Sold today',
                      value: formatKg(todayKg),
                      badge: '${orders.length} orders',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Your inventory'),
              const SizedBox(height: AppSpacing.md),
              listings.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(child: Text('Could not load listings: $e')),
                ),
                data: (items) => items.isEmpty
                    ? _empty()
                    : Column(
                        children: [
                          for (final listing in items) ...[
                            ListingCard(
                              listing: listing,
                              onUpdateStock: () =>
                                  _editStock(context, ref, listing),
                              onEdit: () => _editStock(context, ref, listing),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() => const Padding(
        padding: EdgeInsets.only(top: 56),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 40, color: AppColors.textMuted),
              SizedBox(height: AppSpacing.md),
              Text('No listings yet',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              SizedBox(height: 2),
              Text('Tap + to list your surplus produce',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            ],
          ),
        ),
      );

  Future<void> _editStock(
      BuildContext context, WidgetRef ref, Listing listing) async {
    final newQty = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _StockSheet(listing: listing),
    );
    if (newQty == null || !context.mounted) return;
    try {
      await ref.read(listingsProvider.notifier).updateStock(listing.id, newQty);
      if (context.mounted) {
        _toast(
            context,
            newQty <= 0
                ? '${listing.vegetable} marked sold out'
                : 'Stock updated to ${formatKg(newQty)}');
      }
    } catch (e) {
      if (context.mounted) _toast(context, 'Could not update: $e');
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.eco, color: Colors.white, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const Text('SELLER DASHBOARD',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  )),
            ],
          ),
        ),
        const NotificationBell(),
      ],
    );
  }
}

/// Bottom sheet to adjust a listing's stock (quantity), with a sold-out shortcut.
class _StockSheet extends StatefulWidget {
  const _StockSheet({required this.listing});
  final Listing listing;

  @override
  State<_StockSheet> createState() => _StockSheetState();
}

class _StockSheetState extends State<_StockSheet> {
  late final TextEditingController _qty =
      TextEditingController(text: _fmt(widget.listing.quantityKg));

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  double get _value => double.tryParse(_qty.text.trim()) ?? 0;

  void _bump(double delta) {
    final next = (_value + delta).clamp(0, 1000).toDouble();
    _qty.text = _fmt(next);
    setState(() {});
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update stock · ${widget.listing.vegetable}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('Currently ${formatKg(widget.listing.quantityKg)} available',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _stepBtn(Icons.remove, () => _bump(-1)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _qty,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(suffixText: 'kg'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _stepBtn(Icons.add, () => _bump(1)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Save stock',
            onPressed: () => Navigator.of(context).pop(_value),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(0.0),
              icon: const Icon(Icons.remove_shopping_cart_outlined,
                  size: 18, color: AppColors.danger),
              label: const Text('Mark sold out',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => Material(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      );
}
