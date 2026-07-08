import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/band_chip.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/rescue.dart';

/// Shared card for a rescue, with an optional [action] slot for role-specific
/// buttons (accept, claim, mark picked up / delivered).
class RescueCard extends StatelessWidget {
  const RescueCard({
    super.key,
    required this.rescue,
    this.action,
    this.showNgo = false,
    this.onExplain,
  });

  final Rescue rescue;
  final Widget? action;
  final bool showNgo;

  /// When set, shows a "Why rescue this?" button that fetches an AI explanation.
  final Future<String> Function()? onExplain;

  ChipTone get _tone => switch (rescue.status) {
        RescueStatus.offered => ChipTone.warning,
        RescueStatus.accepted => ChipTone.info,
        RescueStatus.assigned => ChipTone.info,
        RescueStatus.pickedUp => ChipTone.warning,
        RescueStatus.delivered => ChipTone.success,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rescue.vegetable,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${rescue.vendorName} · ${rescue.pickupArea}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusChip(label: rescue.status.label, tone: _tone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _meta(Icons.scale_outlined, formatKg(rescue.quantityKg)),
              const SizedBox(width: AppSpacing.lg),
              _meta(Icons.restaurant_outlined,
                  '~${rescue.estimatedMeals} meals'),
              const SizedBox(width: AppSpacing.lg),
              _meta(Icons.place_outlined,
                  '${rescue.distanceKm.toStringAsFixed(1)} km'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              BandChip(band: rescue.band, timeRange: rescue.timeRange),
              if (showNgo && rescue.ngoName != null) ...[
                const Spacer(),
                Text(
                  rescue.ngoName!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (onExplain != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ExplainSection(onExplain: onExplain!),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
        ],
      );
}

/// "Why rescue this?" — lazily fetches an AI explanation on first tap and
/// reveals it inline. Kept private to the card so callers only pass a fetcher.
class _ExplainSection extends StatefulWidget {
  const _ExplainSection({required this.onExplain});

  final Future<String> Function() onExplain;

  @override
  State<_ExplainSection> createState() => _ExplainSectionState();
}

class _ExplainSectionState extends State<_ExplainSection> {
  String? _text;
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final text = await widget.onExplain();
      if (mounted) setState(() => _text = text);
    } catch (_) {
      if (mounted) {
        setState(() => _text = 'Could not load an explanation right now.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_text != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedMagicWand01,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'WHY RESCUE THIS',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _text!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _loading ? null : _load,
        icon: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const HugeIcon(icon: HugeIcons.strokeRoundedMagicWand01, size: 16),
        label: Text(_loading ? 'Thinking…' : 'Why rescue this?'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
