import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'application/rescue_providers.dart';
import 'domain/rescue.dart';
import 'widgets/rescue_card.dart';

/// A read-only view of the rescue network — the "Transform" leg of
/// Sell → Rescue → Transform. When produce reaches the end of its usable window
/// it's offered to community kitchens and NGOs; this board shows those rescues
/// moving from Available → In transit → Delivered, with a live Bedrock
/// "why rescue this?" explanation on each. No accept/claim actions here (the
/// cook/NGO app drives the lifecycle) — it exists so the surplus-to-meals story
/// is visible end to end.
class RescueBoardScreen extends ConsumerWidget {
  const RescueBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rescuesAsync = ref.watch(rescuesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.refresh(rescuesProvider.future),
              child: rescuesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(children: [
                  const SizedBox(height: 80),
                  Center(child: Text('Could not load rescues: $e')),
                ]),
                data: (rescues) => _board(context, ref, rescues),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 20,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: Colors.white,
                size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rescue network',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Surplus at end-of-life → community kitchens & NGOs',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _board(BuildContext context, WidgetRef ref, List<Rescue> rescues) {
    if (rescues.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 100),
        Icon(Icons.eco_outlined, size: 48, color: AppColors.borderStrong),
        SizedBox(height: 12),
        Center(
          child: Text('No active rescues right now',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
      ]);
    }

    final available =
        rescues.where((r) => r.status == RescueStatus.offered).toList();
    final inProgress = rescues
        .where((r) =>
            r.status == RescueStatus.accepted ||
            r.status == RescueStatus.assigned ||
            r.status == RescueStatus.pickedUp)
        .toList();
    final delivered =
        rescues.where((r) => r.status == RescueStatus.delivered).toList();

    final rescuedKg = rescues.fold<double>(0, (s, r) => s + r.quantityKg);
    final meals =
        rescues.fold<int>(0, (s, r) => s + (r.mealsServed ?? r.estimatedMeals));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        _summary(rescuedKg, meals, delivered.length, available.length),
        const SizedBox(height: AppSpacing.lg),
        if (available.isNotEmpty)
          ..._section(context, ref, 'Available now', available,
              HugeIcons.strokeRoundedAlert02),
        if (inProgress.isNotEmpty)
          ..._section(context, ref, 'In transit', inProgress,
              HugeIcons.strokeRoundedDeliveryTruck02),
        if (delivered.isNotEmpty)
          ..._section(context, ref, 'Delivered', delivered,
              HugeIcons.strokeRoundedCheckmarkBadge01),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _summary(double kg, int meals, int delivered, int available) {
    Widget stat(String value, String label, dynamic icon) => Expanded(
          child: Column(
            children: [
              HugeIcon(icon: icon, color: Colors.white, size: 20),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          stat(formatKg(kg), 'Routed to rescue', HugeIcons.strokeRoundedLeaf02),
          stat('~$meals', 'Meals possible', HugeIcons.strokeRoundedRestaurant01),
          stat('$available', 'Awaiting NGO', HugeIcons.strokeRoundedAlert02),
          stat('$delivered', 'Delivered',
              HugeIcons.strokeRoundedCheckmarkBadge01),
        ],
      ),
    );
  }

  List<Widget> _section(BuildContext context, WidgetRef ref, String title,
      List<Rescue> items, dynamic icon) {
    return [
      Row(
        children: [
          HugeIcon(icon: icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Text('(${items.length})',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted)),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      for (final r in items) ...[
        RescueCard(
          rescue: r,
          showNgo: true,
          onExplain: () => ref.read(rescuesProvider.notifier).explain(r.id),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      const SizedBox(height: AppSpacing.sm),
    ];
  }
}
