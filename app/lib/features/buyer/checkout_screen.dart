import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import 'application/cart_providers.dart';
import 'application/marketplace_providers.dart';
import 'domain/order.dart';
import 'widgets/bill_summary.dart';

/// Self-pickup payment methods (the pilot is pay-on-pickup by default; the
/// others are simulated — no real gateway yet, per the spec's future scope).
enum PayMethod {
  pickup('Pay on pickup', 'PICKUP', Icons.payments_outlined),
  upi('UPI', 'UPI', Icons.qr_code_2_rounded),
  card('Card', 'CARD', Icons.credit_card_rounded),
  wallet('Revivo Wallet', 'WALLET', Icons.account_balance_wallet_outlined);

  const PayMethod(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final List<String> _slots = _pickupSlots();
  late String _slot = _slots.first;
  PayMethod _pay = PayMethod.pickup;
  bool _placing = false;

  /// Six upcoming half-hour self-pickup windows from the next :00/:30.
  List<String> _pickupSlots() {
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day, now.hour,
        now.minute < 30 ? 30 : 0);
    if (now.minute >= 30) start = start.add(const Duration(hours: 1));
    return [
      for (var i = 0; i < 6; i++)
        () {
          final a = start.add(Duration(minutes: 30 * i));
          final b = a.add(const Duration(minutes: 30));
          return '${_hm(a)}–${_hm(b)}';
        }(),
    ];
  }

  String _hm(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  Future<void> _placeOrder() async {
    final items = ref.read(cartProvider);
    if (items.isEmpty) return;
    setState(() => _placing = true);
    try {
      final orders = <Order>[];
      for (final item in items) {
        orders.add(
          await ref.read(ordersProvider.notifier).placeOrder(
                offer: item.offer,
                quantityKg: item.quantityKg,
                pickupSlot: _slot,
                paymentMethod: _pay.value,
              ),
        );
      }
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      context.go('/buyer/order-confirmed', extra: orders);
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not place order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = ref.watch(cartBillProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  const SectionHeader(title: 'Pickup slot'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final s in _slots)
                        ChoiceChip(
                          label: Text(s),
                          selected: _slot == s,
                          onSelected: (_) => setState(() => _slot = s),
                          selectedColor: AppColors.primarySurface,
                          showCheckmark: false,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Payment'),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < PayMethod.values.length; i++) ...[
                          _payRow(PayMethod.values[i]),
                          if (i != PayMethod.values.length - 1)
                            const Divider(height: 1, indent: 52),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Bill'),
                  const SizedBox(height: AppSpacing.sm),
                  BillSummary(bill: bill),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.md, AppSpacing.screen, AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                label: _pay == PayMethod.pickup
                    ? 'Place order · pay on pickup'
                    : 'Pay ${formatMoney(bill.total)} · place order',
                icon: Icons.check_circle_outline,
                loading: _placing,
                onPressed: _placeOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payRow(PayMethod m) {
    final selected = _pay == m;
    return InkWell(
      onTap: () => setState(() => _pay = m),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(m.icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(m.label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.primary : AppColors.borderStrong,
            ),
          ],
        ),
      ),
    );
  }
}
