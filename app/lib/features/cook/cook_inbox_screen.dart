import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/stat_tile.dart';
import '../notifications/widgets/notification_bell.dart';
import '../rescue/application/rescue_providers.dart';
import '../rescue/domain/rescue.dart';
import '../rescue/widgets/async_action_button.dart';
import '../rescue/widgets/rescue_card.dart';
import 'meal_log_sheet.dart';

/// The cook/NGO operations console. Three segments mirror the rescue workflow:
/// what's available to grab, what this kitchen is actively picking up, and what
/// it has delivered (and needs to log meals for). Replaces the single scrolling
/// inbox that didn't scale past a few rescues.
class CookInboxScreen extends ConsumerStatefulWidget {
  const CookInboxScreen({super.key});

  @override
  ConsumerState<CookInboxScreen> createState() => _CookInboxScreenState();
}

enum _Seg { available, pickups, delivered }

class _CookInboxScreenState extends ConsumerState<CookInboxScreen> {
  _Seg _seg = _Seg.available;

  @override
  Widget build(BuildContext context) {
    final rescues = ref.watch(rescuesProvider);
    final ngoName = ref.watch(sessionProvider)?.name ?? 'Annapoorna Trust';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(rescuesProvider.future),
          child: rescues.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(child: Text('Could not load rescues: $e')),
              ),
            ]),
            data: (items) => _console(context, items, ngoName),
          ),
        ),
      ),
    );
  }

  Widget _console(BuildContext context, List<Rescue> items, String ngoName) {
    final available = items.where((r) => r.status == RescueStatus.offered).toList()
      ..sort(_byUrgency);
    final pickups = items
        .where((r) =>
            r.status != RescueStatus.offered &&
            r.status != RescueStatus.delivered)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final delivered =
        items.where((r) => r.status == RescueStatus.delivered).toList();

    final counts = {
      _Seg.available: available.length,
      _Seg.pickups: pickups.length,
      _Seg.delivered: delivered.length,
    };

    final body = switch (_seg) {
      _Seg.available => _available(context, available, ngoName),
      _Seg.pickups => _pickups(context, pickups),
      _Seg.delivered => _delivered(context, delivered),
    };

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        _Header(name: ngoName),
        const SizedBox(height: AppSpacing.lg),
        _segments(counts),
        const SizedBox(height: AppSpacing.lg),
        ...body,
      ],
    );
  }

  /// Most urgent (Rescue band) then nearest first — the triage order. Higher
  /// band index (rescue=2) is more urgent, so it sorts ahead.
  int _byUrgency(Rescue a, Rescue b) {
    final band = b.band.index.compareTo(a.band.index);
    if (band != 0) return band;
    return a.distanceKm.compareTo(b.distanceKm);
  }

  Widget _segments(Map<_Seg, int> counts) {
    Widget chip(_Seg seg, String label) {
      final selected = _seg == seg;
      final count = counts[seg] ?? 0;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _seg = seg),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    )),
                if (count > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : AppColors.textSecondary,
                        )),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(_Seg.available, 'Available'),
        const SizedBox(width: AppSpacing.sm),
        chip(_Seg.pickups, 'My pickups'),
        const SizedBox(width: AppSpacing.sm),
        chip(_Seg.delivered, 'Delivered'),
      ],
    );
  }

  List<Widget> _available(
      BuildContext context, List<Rescue> items, String ngoName) {
    final meals = items.fold<int>(0, (s, r) => s + r.estimatedMeals);
    return [
      Row(
        children: [
          Expanded(
            child: StatTile(
                label: 'New rescues',
                value: '${items.length}',
                badge: 'Nearby'),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatTile(
                label: 'Meals available', value: '~$meals', badge: 'Today'),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      if (items.isEmpty)
        _emptyLine('No new rescues right now — you\'re all caught up.')
      else
        for (final r in items) ...[
          RescueCard(
            rescue: r,
            onExplain: () => ref.read(rescuesProvider.notifier).explain(r.id),
            action: AsyncActionButton(
              label: 'Accept · ~${r.estimatedMeals} meals',
              icon: Icons.volunteer_activism_outlined,
              onRun: () async {
                await ref
                    .read(rescuesProvider.notifier)
                    .accept(r.id, ngoName: ngoName);
                if (context.mounted) {
                  _toast(context, 'Accepted — see it under My pickups');
                  setState(() => _seg = _Seg.pickups);
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
    ];
  }

  List<Widget> _pickups(BuildContext context, List<Rescue> items) {
    if (items.isEmpty) {
      return [_emptyLine('No active pickups. Grab one from Available.')];
    }
    return [
      for (final r in items) ...[
        RescueCard(
          rescue: r,
          showNgo: true,
          action: Column(
            children: [
              _navRow(context, r),
              const SizedBox(height: AppSpacing.sm),
              _nextAction(context, r) ?? const SizedBox.shrink(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  List<Widget> _delivered(BuildContext context, List<Rescue> items) {
    if (items.isEmpty) {
      return [_emptyLine('Nothing delivered yet — completed rescues land here.')];
    }
    return [
      for (final r in items) ...[
        RescueCard(
          rescue: r,
          showNgo: true,
          action: _mealProof(context, r),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  /// Directions + call the vendor for an active pickup.
  Widget _navRow(BuildContext context, Rescue r) {
    final maps = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${r.vendorName}, ${r.pickupArea}, Coimbatore')}');
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _open(context, maps),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedDirections01, size: 18),
            label: Text('Directions · ${r.distanceKm.toStringAsFixed(1)} km'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => _open(context, Uri.parse('tel:+919000000000')),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const HugeIcon(icon: HugeIcons.strokeRoundedCall, size: 18),
        ),
      ],
    );
  }

  /// After delivery the cook records meals served — the persisted Transform
  /// proof (with an optional photo).
  Widget _mealProof(BuildContext context, Rescue r) {
    if (r.isLogged) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                r.mealPhotoKey != null && r.mealPhotoKey!.isNotEmpty
                    ? Icons.verified_rounded
                    : Icons.check_circle_outline,
                size: 18,
                color: AppColors.primary),
            const SizedBox(width: 6),
            Text('${r.mealsServed} meals served',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark)),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => showMealLogSheet(context, ref, r),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedRestaurant01, size: 18),
      label: const Text('Log meals served'),
    );
  }

  /// The cook drives the rescue through to delivery (no volunteers).
  Widget? _nextAction(BuildContext context, Rescue r) {
    final notifier = ref.read(rescuesProvider.notifier);
    return switch (r.status) {
      RescueStatus.accepted => AsyncActionButton(
          label: 'Start pickup',
          icon: Icons.directions_run_outlined,
          onRun: () => notifier.claimPickup(r.id),
        ),
      RescueStatus.assigned => AsyncActionButton(
          label: 'Mark collected',
          icon: Icons.inventory_2_outlined,
          onRun: () => notifier.markPickedUp(r.id),
        ),
      RescueStatus.pickedUp => AsyncActionButton(
          label: 'Mark delivered',
          icon: Icons.check_circle_outline,
          onRun: () async {
            await notifier.markDelivered(r.id);
            if (context.mounted) {
              _toast(context, 'Delivered — log the meal under Delivered 🌱');
              setState(() => _seg = _Seg.delivered);
            }
          },
        ),
      _ => null,
    };
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      _toast(context, 'Could not open that');
    }
  }

  Widget _emptyLine(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const HugeIcon(icon: HugeIcons.strokeRoundedPot01, color: Colors.white, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const Text('RESCUE KITCHEN',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  )),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/buyer/map'),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedSatellite01, color: AppColors.primary),
          tooltip: 'Rescue radar',
        ),
        const NotificationBell(),
      ],
    );
  }
}
