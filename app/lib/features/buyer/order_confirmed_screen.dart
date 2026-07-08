import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import 'domain/order.dart';

/// Post-checkout confirmation for one or more orders placed together.
class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key, required this.orders});

  final List<Order> orders;

  double get _total => orders.fold(0, (s, o) => s + o.total);
  double get _saved => orders.fold(0, (s, o) => s + o.saved);
  int get _vendors => orders.map((o) => o.vendorName).toSet().length;
  String get _slot => orders.isEmpty ? '' : orders.first.pickupSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Order placed!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                '${orders.length} ${orders.length == 1 ? 'item' : 'items'} from '
                '$_vendors ${_vendors == 1 ? 'vendor' : 'vendors'} — being prepared',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                child: Column(
                  children: [
                    for (final o in orders) ...[
                      _line(o),
                      const Divider(height: AppSpacing.lg),
                    ],
                    _row('Total', formatMoney(_total), bold: true),
                    if (_slot.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _row('Pickup slot', _slot),
                    ],
                    if (_saved > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          'You saved ${formatMoney(_saved)} vs market price 🌱',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Track my orders',
                onPressed: () => context.go('/buyer/orders'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go('/buyer/home'),
                child: const Text('Back to market'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(Order o) => Row(
        children: [
          Expanded(
            child: Text('${o.vegetable} · ${formatKg(o.quantityKg)}',
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          Text(formatMoney(o.total),
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13.5, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
