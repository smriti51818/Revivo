import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../notifications/widgets/notification_bell.dart';
import '../rescue/application/meal_log_providers.dart';
import '../rescue/application/rescue_providers.dart';
import '../rescue/domain/rescue.dart';
import '../rescue/widgets/async_action_button.dart';
import '../rescue/widgets/rescue_card.dart';
import 'meal_log_sheet.dart';

class CookInboxScreen extends ConsumerWidget {
  const CookInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rescues = ref.watch(rescuesProvider);
    ref.watch(mealLogProvider); // rebuild once meals are logged
    final ngoName = ref.watch(sessionProvider)?.name ?? 'Annapoorna Trust';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(rescuesProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              _Header(name: ngoName),
              const SizedBox(height: AppSpacing.xl),
              rescues.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(child: Text('Could not load rescues: $e')),
                ),
                data: (items) => _content(context, ref, items, ngoName),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, List<Rescue> items,
      String ngoName) {
    final incoming =
        items.where((r) => r.status == RescueStatus.offered).toList();
    final active = items
        .where((r) =>
            r.status != RescueStatus.offered &&
            r.status != RescueStatus.delivered)
        .toList();
    final delivered =
        items.where((r) => r.status == RescueStatus.delivered).toList();
    final mealsAvailable =
        incoming.fold<int>(0, (sum, r) => sum + r.estimatedMeals);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'New rescues',
                value: '${incoming.length}',
                badge: 'Nearby',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatTile(
                label: 'Meals available',
                value: '~$mealsAvailable',
                badge: 'Today',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'New rescues near you'),
        const SizedBox(height: AppSpacing.md),
        if (incoming.isEmpty)
          _emptyLine('No new rescues right now — you\'re all caught up.')
        else
          for (final r in incoming) ...[
            RescueCard(
              rescue: r,
              onExplain: () =>
                  ref.read(rescuesProvider.notifier).explain(r.id),
              action: AsyncActionButton(
                label: 'Accept · ~${r.estimatedMeals} meals',
                icon: Icons.volunteer_activism_outlined,
                onRun: () async {
                  await ref
                      .read(rescuesProvider.notifier)
                      .accept(r.id, ngoName: ngoName);
                  if (context.mounted) {
                    _toast(context, 'Rescue accepted — arrange pickup below');
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        if (active.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const SectionHeader(title: 'In progress'),
          const SizedBox(height: AppSpacing.md),
          for (final r in active) ...[
            RescueCard(
              rescue: r,
              showNgo: true,
              action: _nextAction(context, ref, r),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (delivered.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const SectionHeader(title: 'Delivered · log the meal'),
          const SizedBox(height: AppSpacing.md),
          for (final r in delivered) ...[
            RescueCard(
              rescue: r,
              showNgo: true,
              action: _mealProof(context, ref, r),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ],
    );
  }

  /// After delivery the cook records meals served — the Transform proof.
  Widget _mealProof(BuildContext context, WidgetRef ref, Rescue r) {
    final served = ref.read(mealLogProvider)[r.id];
    if (served != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('$served meals served',
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
      icon: const Icon(Icons.restaurant_rounded, size: 18),
      label: const Text('Log meals served'),
    );
  }

  /// The cook now drives the rescue through to delivery (no volunteers).
  Widget? _nextAction(BuildContext context, WidgetRef ref, Rescue r) {
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
              _toast(context,
                  'Delivered — ~${r.estimatedMeals} meals served 🌱');
            }
          },
        ),
      _ => null,
    };
  }

  Widget _emptyLine(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary),
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
          child: const Icon(Icons.soup_kitchen, color: Colors.white, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const Text(
                'RESCUE KITCHEN',
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const NotificationBell(),
      ],
    );
  }
}
