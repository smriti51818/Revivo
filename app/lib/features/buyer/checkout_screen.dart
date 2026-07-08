import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import 'application/cart_providers.dart';
import 'application/failed_payments_providers.dart';
import 'application/marketplace_providers.dart';
import 'application/wallet_providers.dart';
import 'domain/cart_item.dart';
import 'domain/failed_payment.dart';
import 'domain/order.dart';
import 'widgets/bill_summary.dart';
import 'widgets/payment_sheet.dart';

/// Self-pickup payment methods (the pilot is pay-on-pickup by default; the
/// others are simulated — no real gateway yet, per the spec's future scope).
/// Revivo credits are handled separately, as a redeemable balance.
enum PayMethod {
  pickup('Pay on pickup', 'PICKUP', Icons.payments_outlined),
  upi('UPI', 'UPI', Icons.qr_code_2_rounded),
  card('Card', 'CARD', Icons.credit_card_rounded);

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
  bool _useCredits = false;
  bool _placing = false;

  /// Credits redeemable against a bill total, given the current balance.
  int _creditFor(int balance, double total) =>
      _useCredits ? min(balance, total.floor()) : 0;

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
    final bill = ref.read(cartBillProvider);
    final credit = _creditFor(ref.read(walletProvider), bill.total);
    final payable = (bill.total - credit).clamp(0, bill.total).toDouble();
    setState(() => _placing = true);

    // Online methods run through the simulated gateway — unless credits cover
    // the whole bill, in which case there's nothing left to charge.
    if (_pay != PayMethod.pickup && payable > 0) {
      final paid = await showPaymentSheet(
        context,
        amount: payable,
        methodLabel: _pay.label,
        methodIcon: _pay.icon,
      );
      if (!mounted) return;
      if (paid == null) {
        setState(() => _placing = false); // dismissed — stay on checkout
        return;
      }
      if (paid == false) {
        _recordFailure(items, payable);
        setState(() => _placing = false); // keep the cart so they can retry
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Payment failed — saved under your orders')));
        context.go('/buyer/orders');
        return;
      }
    }

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
      // Settle the wallet: redeem what was used, then earn from the savings.
      ref.read(walletProvider.notifier).spend(credit);
      ref.read(walletProvider.notifier).earnFromSaved(bill.totalSaved);
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

  /// Snapshots the cart into a [FailedPayment] so it shows under "Payment
  /// failed" in My Orders with a path back to retry.
  void _recordFailure(List<CartItem> items, double amount) {
    ref.read(failedPaymentsProvider.notifier).add(
          FailedPayment(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            lines: [
              for (final i in items)
                FailedPaymentLine(
                  vegetable: i.offer.vegetable,
                  vendorName: i.offer.vendorName,
                  quantityKg: i.quantityKg,
                  pricePerKg: i.unitPrice,
                  imageUrl: i.offer.imageUrl,
                ),
            ],
            amount: amount,
            method: _pay.value,
            pickupSlot: _slot,
            attemptedAt: DateTime.now(),
            reason: 'Payment declined by ${_pay.label}',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bill = ref.watch(cartBillProvider);
    final balance = ref.watch(walletProvider);
    final credit = _creditFor(balance, bill.total);
    final payable = (bill.total - credit).clamp(0, bill.total).toDouble();
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
                  if (balance > 0) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(title: 'Revivo credits'),
                    const SizedBox(height: AppSpacing.sm),
                    _creditsCard(balance, credit),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Bill'),
                  const SizedBox(height: AppSpacing.sm),
                  BillSummary(bill: bill),
                  if (credit > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        children: [
                          _payRowMini('Revivo credits',
                              '− ${formatMoney(credit.toDouble())}',
                              highlight: true),
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1),
                          ),
                          _payRowMini('Payable now', formatMoney(payable),
                              bold: true),
                        ],
                      ),
                    ),
                  ],
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
                    ? (credit > 0
                        ? 'Place order · ${formatMoney(payable)} on pickup'
                        : 'Place order · pay on pickup')
                    : payable <= 0
                        ? 'Place order · paid with credits'
                        : 'Pay ${formatMoney(payable)} · place order',
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

  Widget _creditsCard(int balance, int credit) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 4),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeTrackColor: AppColors.primary,
        value: _useCredits,
        onChanged: (v) => setState(() => _useCredits = v),
        secondary: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const HugeIcon(icon: HugeIcons.strokeRoundedWallet01,
              color: AppColors.primary, size: 20),
        ),
        title: Text('Use ${formatMoney(balance.toDouble())} in credits',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(
          _useCredits && credit > 0
              ? '${formatMoney(credit.toDouble())} applied to this order'
              : 'Redeem your rescued-savings credits',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _payRowMini(String label, String value,
      {bool highlight = false, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 15 : 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color:
                    highlight ? AppColors.primary : AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight: FontWeight.w800,
                color: highlight ? AppColors.primary : AppColors.textPrimary)),
      ],
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
