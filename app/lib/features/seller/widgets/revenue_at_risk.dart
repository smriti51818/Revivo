import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/discovery/vendor_directory.dart';
import '../../../core/format.dart';
import '../../../core/models/freshness.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/freshness_countdown.dart';
import '../../rescue/application/rescue_providers.dart';
import '../application/listings_providers.dart';
import '../domain/listing.dart';

/// The seller's answer to the buyer's live countdown: a running tally of the
/// rupee value that freshness decay is eroding right now, with one-tap actions
/// to route a lot to the rescue network before it expires. This is what makes
/// the time-aware thesis actionable for the *supply* side.
class RevenueAtRisk extends ConsumerStatefulWidget {
  const RevenueAtRisk({super.key});

  @override
  ConsumerState<RevenueAtRisk> createState() => _RevenueAtRiskState();
}

class _RevenueAtRiskState extends ConsumerState<RevenueAtRisk> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Re-evaluate bands + at-risk value every second as the clocks tick.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(listingsProvider).valueOrNull ?? const <Listing>[];
    final now = DateTime.now();

    final live = listings
        .where((l) => l.quantityKg > 0 && !(l.hasClock && !l.expiresAt!.isAfter(now)))
        .toList();
    final atRisk = live.where((l) => l.atRisk(now)).toList()
      ..sort((a, b) {
        final ax = a.expiresAt, bx = b.expiresAt;
        if (ax == null || bx == null) return 0;
        return ax.compareTo(bx);
      });

    if (atRisk.isEmpty) return _allClear(live.isEmpty);

    final riskValue = atRisk.fold<double>(0, (s, l) => s + l.liveValue(now));
    final lost =
        atRisk.fold<double>(0, (s, l) => s + (l.freshValue - l.liveValue(now)));
    final nextDrop = _soonestDrop(live, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(riskValue, lost, atRisk.length, nextDrop),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Text('Act before it expires',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('${atRisk.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final l in atRisk) ...[
          _nudge(l, now),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  /// The soonest future band-crossing across all live lots — "next price drop".
  DateTime? _soonestDrop(List<Listing> live, DateTime now) {
    DateTime? soonest;
    for (final l in live) {
      final d = l.nextDropAt(now);
      if (d == null || !d.isAfter(now)) continue;
      if (soonest == null || d.isBefore(soonest)) soonest = d;
    }
    return soonest;
  }

  Widget _hero(double riskValue, double lost, int count, DateTime? nextDrop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), AppColors.danger],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01,
                  color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text('Revenue at risk',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(formatMoney(riskValue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1,
              )),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'lot' : 'lots'} decaying · '
            '${formatMoney(lost)} already lost to freshness',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92), fontSize: 12.5),
          ),
          if (nextDrop != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DropCountdown(target: nextDrop),
          ],
        ],
      ),
    );
  }

  Widget _nudge(Listing l, DateTime now) {
    final band = l.liveBand(now);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l.vegetable} · ${formatKg(l.quantityKg)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Worth ${formatMoney(l.liveValue(now))} now · '
                      'was ${formatMoney(l.freshValue)}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (l.hasClock)
                FreshnessCountdownPill(
                  expiresAt: l.expiresAt!,
                  totalHours: l.totalHours!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _routeToRescue(l, band),
                  style: FilledButton.styleFrom(
                    backgroundColor: band == FreshnessBand.rescue
                        ? AppColors.danger
                        : AppColors.warning,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(42),
                  ),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedFavourite, size: 18),
                  label: const Text('Route to rescue'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => _markSold(l),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('Sold out'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _routeToRescue(Listing l, FreshnessBand band) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Route to rescue network?'),
        content: Text(
          '${formatKg(l.quantityKg)} of ${l.vegetable} will be offered to '
          'nearby kitchens and removed from the buyer market. This keeps it '
          'out of landfill when it can no longer be sold fresh.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Route it')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final name = ref.read(sessionProvider)?.name ?? 'Vendor';
    try {
      await ref.read(rescueRepositoryProvider).createRescue(
            vendorName: name,
            pickupArea: vendorInfo(name).area,
            vegetable: l.vegetable,
            quantityKg: l.quantityKg,
            band: band,
            timeRange: l.timeRange,
          );
      // Pull it off the buyer market — it lives on the rescue board now.
      await ref.read(listingsProvider.notifier).updateStock(l.id, 0);
      _toast('${l.vegetable} routed to rescue — kitchens notified 🌱');
    } catch (e) {
      _toast('Could not route to rescue: $e');
    }
  }

  Future<void> _markSold(Listing l) async {
    try {
      await ref.read(listingsProvider.notifier).updateStock(l.id, 0);
      _toast('${l.vegetable} marked sold out');
    } catch (e) {
      _toast('Could not update: $e');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _allClear(bool empty) {
    if (empty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge01, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'All your stock is fresh — nothing at risk right now.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// White-on-gradient "next price drop in mm:ss" chip that ticks every second.
class _DropCountdown extends StatefulWidget {
  const _DropCountdown({required this.target});
  final DateTime target;

  @override
  State<_DropCountdown> createState() => _DropCountdownState();
}

class _DropCountdownState extends State<_DropCountdown> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.target.difference(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            'Next price drop in ${formatCountdown(remaining)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
