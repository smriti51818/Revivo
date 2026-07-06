import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../rescue/application/rescue_providers.dart';
import '../rescue/domain/rescue.dart';
import '../rescue/widgets/async_action_button.dart';
import '../rescue/widgets/rescue_card.dart';

class VolunteerTasksScreen extends ConsumerWidget {
  const VolunteerTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rescues = ref.watch(rescuesProvider);
    final name = ref.watch(sessionProvider)?.name ?? 'Volunteer';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(rescuesProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              _Header(
                name: name,
                onSignOut: () {
                  ref.read(sessionProvider.notifier).signOut();
                  context.go('/role');
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              rescues.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(child: Text('Could not load tasks: $e')),
                ),
                data: (items) => _content(context, ref, items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, List<Rescue> items) {
    final available =
        items.where((r) => r.status == RescueStatus.accepted).toList();
    final active = items
        .where((r) =>
            r.status == RescueStatus.assigned ||
            r.status == RescueStatus.pickedUp)
        .toList();
    final done =
        items.where((r) => r.status == RescueStatus.delivered).toList();
    final kgMoved = done.fold<double>(0, (sum, r) => sum + r.quantityKg);
    final mealsDelivered = done.fold<int>(0, (sum, r) => sum + r.estimatedMeals);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Active pickups',
                value: '${active.length}',
                badge: 'Now',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatTile(
                label: 'Meals delivered',
                value: '~$mealsDelivered',
                badge: formatKg(kgMoved),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Available pickups'),
        const SizedBox(height: AppSpacing.md),
        if (available.isEmpty)
          _emptyLine('No pickups waiting — thank you for helping!')
        else
          for (final r in available) ...[
            RescueCard(
              rescue: r,
              showNgo: true,
              action: AsyncActionButton(
                label: 'Claim pickup',
                icon: Icons.pan_tool_alt_outlined,
                onRun: () => ref.read(rescuesProvider.notifier).claimPickup(r.id),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        if (active.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const SectionHeader(title: 'Your active tasks'),
          const SizedBox(height: AppSpacing.md),
          for (final r in active) ...[
            RescueCard(
              rescue: r,
              showNgo: true,
              action: r.status == RescueStatus.assigned
                  ? AsyncActionButton(
                      label: 'Mark picked up',
                      icon: Icons.local_shipping_outlined,
                      onRun: () =>
                          ref.read(rescuesProvider.notifier).markPickedUp(r.id),
                    )
                  : AsyncActionButton(
                      label: 'Mark delivered',
                      icon: Icons.check_circle_outline,
                      onRun: () async {
                        await ref
                            .read(rescuesProvider.notifier)
                            .markDelivered(r.id);
                        if (context.mounted) {
                          _toast(context,
                              'Delivered — ~${r.estimatedMeals} meals on the way 🌱');
                        }
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const SectionHeader(title: 'Completed'),
          const SizedBox(height: AppSpacing.md),
          for (final r in done) ...[
            RescueCard(rescue: r, showNgo: true),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ],
    );
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
  const _Header({required this.name, required this.onSignOut});
  final String name;
  final VoidCallback onSignOut;

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
          child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
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
                'VOLUNTEER · PICKUPS',
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
        IconButton(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout, size: 20),
          color: AppColors.textSecondary,
          tooltip: 'Sign out',
        ),
      ],
    );
  }
}
