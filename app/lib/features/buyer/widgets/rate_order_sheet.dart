import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/marketplace_providers.dart';
import '../domain/order.dart';

const _quickTags = [
  'Fresh',
  'On time',
  'Great value',
  'Good quality',
  'Friendly',
];

/// Opens the rate-order bottom sheet for a completed order.
Future<void> showRateOrderSheet(
  BuildContext context,
  WidgetRef ref,
  Order order,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _RateSheet(order: order, parentRef: ref),
  );
}

class _RateSheet extends StatefulWidget {
  const _RateSheet({required this.order, required this.parentRef});
  final Order order;
  final WidgetRef parentRef;

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  int _stars = 0;
  final Set<String> _tags = {};
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.parentRef.read(ordersProvider.notifier).rateOrder(
            orderId: widget.order.id,
            stars: _stars,
            tags: _tags.toList(),
            comment: _comment.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Thanks for rating this rescue 🌱')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not submit: $e')));
    }
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
          const Text('Rate your rescue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            '${widget.order.vegetable} · ${widget.order.vendorName}',
            style:
                const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _stars = i),
                  iconSize: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(),
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedStar,
                    size: 30,
                    color: i <= _stars ? AppColors.warning : AppColors.borderStrong,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in _quickTags)
                FilterChip(
                  label: Text(t),
                  selected: _tags.contains(t),
                  onSelected: (on) => setState(
                      () => on ? _tags.add(t) : _tags.remove(t)),
                  selectedColor: AppColors.primarySurface,
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _comment,
            maxLength: 280,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a note (optional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Submit rating',
            loading: _saving,
            onPressed: _stars > 0 ? _submit : null,
          ),
        ],
      ),
    );
  }
}
