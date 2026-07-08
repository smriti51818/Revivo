import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/cart_providers.dart';

/// A persistent "N items · ₹total · View cart" bar that slides up from the
/// bottom whenever the cart has something in it — the Zomato/Blinkit pattern.
/// Drop it in as a `bottomNavigationBar`; it collapses to nothing when empty.
class CartBar extends ConsumerWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final kg = ref.watch(cartKgProvider);
    final bill = ref.watch(cartBillProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: count == 0
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : _Bar(
              key: const ValueKey('bar'),
              count: count,
              kg: kg,
              total: bill.total,
            ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.count,
    required this.kg,
    required this.total,
  });

  final int count;
  final double kg;
  final double total;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.button),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.45),
          child: InkWell(
            onTap: () => context.push('/buyer/cart'),
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 12),
              child: Row(
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedShoppingBag01,
                      color: Colors.white, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count ${count == 1 ? 'item' : 'items'} · ${formatKg(kg)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatMoney(total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'View cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
