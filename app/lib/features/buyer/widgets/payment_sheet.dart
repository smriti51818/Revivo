import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';

/// Simulated online-payment sheet. Returns `true` on success, `false` when the
/// payment is declined (the demo's "failed payment" path), or `null` if the
/// buyer dismisses it. There is no real gateway in the pilot — this models both
/// outcomes so the failed-payments flow is demoable.
Future<bool?> showPaymentSheet(
  BuildContext context, {
  required double amount,
  required String methodLabel,
  required IconData methodIcon,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _PaymentSheet(
      amount: amount,
      methodLabel: methodLabel,
      methodIcon: methodIcon,
    ),
  );
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.amount,
    required this.methodLabel,
    required this.methodIcon,
  });

  final double amount;
  final String methodLabel;
  final IconData methodIcon;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  bool _processing = false;

  Future<void> _pay() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.of(context).pop(true);
  }

  void _fail() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(widget.methodIcon,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pay via ${widget.methodLabel}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                      const Text('Secured by Revivo',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(formatMoney(widget.amount),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_processing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.4)),
                    SizedBox(width: AppSpacing.md),
                    Text('Processing payment…',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else ...[
              PrimaryButton(
                label: 'Pay ${formatMoney(widget.amount)}',
                icon: HugeIcons.strokeRoundedLockKey,
                onPressed: _pay,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: _fail,
                  child: const Text('Simulate a failed payment',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
