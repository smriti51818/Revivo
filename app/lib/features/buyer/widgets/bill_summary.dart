import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/cart_item.dart';

/// Itemised bill — item total, savings, platform fee, grand total. Shared by
/// the cart and checkout so the numbers are always presented identically.
class BillSummary extends StatelessWidget {
  const BillSummary({super.key, required this.bill});

  final CartBill bill;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _row('Item total', formatMoney(bill.itemTotal)),
          if (bill.saved > 0) ...[
            const SizedBox(height: 8),
            _row('You save vs market', '− ${formatMoney(bill.saved)}',
                highlight: true),
          ],
          const SizedBox(height: 8),
          _row('Platform fee', formatMoney(bill.platformFee)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1),
          ),
          _row('To pay', formatMoney(bill.total), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool highlight = false, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 13.5,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: FontWeight.w800,
            color: highlight
                ? AppColors.primary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
