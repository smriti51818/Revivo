import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import 'application/impact_providers.dart';
import 'domain/impact.dart';

/// Litres of water kept in the system per kg of produce rescued (conservative
/// vegetable blue-water footprint; shown as an estimate).
const double _waterPerKg = 26;

class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impact = ref.watch(impactProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(impactProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              const Text(
                'Community impact',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Coimbatore pilot · this week',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              impact.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(child: Text('Could not load impact: $e')),
                ),
                data: (data) => _content(data),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(ImpactData data) {
    final s = data.summary;
    final water = s.kgRescued * _waterPerKg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(s),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'What this rescued'),
        const SizedBox(height: AppSpacing.md),
        _metricsGrid(s, water),
        const SizedBox(height: AppSpacing.lg),
        _goalCard(s),
        const SizedBox(height: AppSpacing.lg),
        _counterfactual(s),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Top rescuers'),
        const SizedBox(height: AppSpacing.md),
        for (final e in data.leaderboard) ...[
          _LeaderRow(
            entry: e,
            maxKg: data.leaderboard.isEmpty ? 1 : data.leaderboard.first.kg,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _hero(ImpactSummary s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
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
              const Icon(Icons.eco, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                'Surplus rescued from waste',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatCount(s.kgRescued),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'kg',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'across ${s.activeVendors} vendors and ${s.activeNgos} kitchens',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline,
                    color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(
                  '${formatCount(s.kgRescued)} kg diverted from landfill',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(ImpactSummary s, double water) {
    final tiles = <Widget>[
      _metric(Icons.restaurant, '~${formatCount(s.mealsServed)}', 'Meals served'),
      _metric(Icons.cloud_outlined, '${formatCount(s.co2SavedKg)} kg',
          'CO₂ avoided'),
      _metric(Icons.water_drop_outlined, '${formatCount(water)} L',
          'Water saved'),
      _metric(Icons.savings_outlined, '₹${formatCount(s.moneySaved)}',
          'Value recovered'),
      _metric(Icons.storefront_outlined, '${s.activeVendors}', 'Vendors'),
      _metric(Icons.soup_kitchen_outlined, '${s.activeNgos}', 'Kitchens'),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          Row(
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: i + 1 < tiles.length
                      ? tiles[i + 1]
                      : const SizedBox.shrink()),
            ],
          ),
          if (i + 2 < tiles.length) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(ImpactSummary s) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly meal goal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                '${(s.goalProgress * 100).round()}%',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: s.goalProgress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatCount(s.mealsServed)} of ${formatCount(s.mealsGoal)} meals served',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// The "would have been wasted without Revivo" counterfactual.
  Widget _counterfactual(ImpactSummary s) {
    return AppCard(
      color: AppColors.warningSurface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.trending_down_rounded,
              size: 22, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Without Revivo this week',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '≈ ${formatCount(s.kgRescued)} kg dumped, '
                  '${formatCount(s.co2SavedKg)} kg CO₂ released, and '
                  '~${formatCount(s.mealsServed)} meals never served.',
                  style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry, required this.maxKg});
  final LeaderboardEntry entry;
  final double maxKg;

  Color get _medal => switch (entry.rank) {
        1 => const Color(0xFFF5B301),
        2 => const Color(0xFF9AA0A6),
        3 => const Color(0xFFCD7F32),
        _ => AppColors.surfaceAlt,
      };

  @override
  Widget build(BuildContext context) {
    final medalled = entry.rank <= 3;
    final frac = maxKg <= 0 ? 0.0 : (entry.kg / maxKg).clamp(0.05, 1.0);
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: medalled ? _medal : AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: medalled ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.role,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatCount(entry.kg)} kg',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                '~${formatCount(entry.meals)} meals',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
