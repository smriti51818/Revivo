import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/cart_providers.dart';
import '../domain/coupon.dart';

/// Bottom sheet listing Revivo's coupons; applies or removes one against the
/// current cart. Eligibility is checked against the live item total.
Future<void> showCouponSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _CouponSheet(),
  );
}

class _CouponSheet extends ConsumerWidget {
  const _CouponSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applied = ref.watch(appliedCouponProvider);
    final itemTotal = ref.watch(cartBillProvider).itemTotal;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md,
            AppSpacing.screen, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Revivo coupons',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text('Applied at checkout on your rescue order',
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            for (final c in kRevivoCoupons) ...[
              _CouponRow(
                coupon: c,
                itemTotal: itemTotal,
                applied: applied?.code == c.code,
                onApply: () {
                  ref.read(appliedCouponProvider.notifier).apply(c);
                  Navigator.of(context).pop();
                },
                onRemove: () {
                  ref.read(appliedCouponProvider.notifier).clear();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _CouponRow extends StatelessWidget {
  const _CouponRow({
    required this.coupon,
    required this.itemTotal,
    required this.applied,
    required this.onApply,
    required this.onRemove,
  });

  final Coupon coupon;
  final double itemTotal;
  final bool applied;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final eligible = coupon.eligible(itemTotal);
    final short = itemTotal < coupon.minOrder
        ? coupon.minOrder - itemTotal
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: applied ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: applied ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Text(
                  coupon.code,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coupon.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(coupon.description,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary)),
                if (!eligible) ...[
                  const SizedBox(height: 4),
                  Text('Add ${formatMoney(short)} more to unlock',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (applied)
            TextButton(
              onPressed: onRemove,
              child: const Text('Remove',
                  style: TextStyle(color: AppColors.danger)),
            )
          else
            TextButton(
              onPressed: eligible ? onApply : null,
              child: const Text('Apply'),
            ),
        ],
      ),
    );
  }
}
