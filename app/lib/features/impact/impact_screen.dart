import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_spacing.dart';
import 'application/impact_providers.dart';
import 'domain/impact.dart';

/// Litres of water kept in the system per kg of produce rescued (a conservative
/// vegetable blue-water footprint; shown as an estimate, derived — not stored).
const double _waterPerKg = 26;

const _green = Color(0xFF27AE60);
const _greenDark = Color(0xFF1B4332);
const _greenSurface = Color(0xFFF2F9F3);
const _greenBorder = Color(0xFFD4E9D9);

/// Community-wide impact for the pilot, driven entirely by [impactProvider]
/// (server-side `aggregate_impact` when live, the seeded in-memory summary
/// offline). Every number here is bound to [ImpactData] — nothing is hardcoded.
class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impact = ref.watch(impactProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(impactProvider.future),
          color: _green,
          child: impact.when(
            loading: () => ListView(
              children: const [
                SizedBox(height: 240),
                Center(child: CircularProgressIndicator(color: _green)),
              ],
            ),
            error: (e, _) => ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                _buildHeader(),
                const SizedBox(height: 48),
                Center(child: Text('Could not load impact: $e')),
              ],
            ),
            data: (data) => ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildBanner(),
                const SizedBox(height: 24),
                _buildAtAGlance(data.summary),
                const SizedBox(height: 24),
                _buildGoal(data.summary),
                const SizedBox(height: 24),
                _buildCommunityImpact(data.summary),
                const SizedBox(height: 24),
                _buildRescueCta(context),
                const SizedBox(height: 24),
                _buildPlanetImpact(data.summary),
                const SizedBox(height: 24),
                _buildLeaderboard(data.leaderboard),
                const SizedBox(height: 24),
                _buildFooterCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Impact',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Making a positive difference with every meal',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        HugeIcon(
            icon: HugeIcons.strokeRoundedNotification02,
            size: 20,
            color: Colors.grey.shade800),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _greenSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                )
              ],
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedLeaf02,
              color: _green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good for People. Good for Planet.',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _greenDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thank you for being a part of a movement towards a better tomorrow.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtAGlance(ImpactSummary s) {
    final water = s.kgRescued * _waterPerKg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilot at a Glance',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGlanceItem(HugeIcons.strokeRoundedRestaurant01,
                    '${formatCount(s.kgRescued)} kg', 'Food Waste\nPrevented'),
              ),
              Expanded(
                child: _buildGlanceItem(HugeIcons.strokeRoundedUserMultiple,
                    formatCount(s.mealsServed), 'Meals Provided'),
              ),
              Expanded(
                child: _buildGlanceItem(HugeIcons.strokeRoundedDroplet,
                    '${formatCount(water)} L', 'Water Saved'),
              ),
              Expanded(
                child: _buildGlanceItem(HugeIcons.strokeRoundedCloudUpload,
                    '${formatCount(s.co2SavedKg)} kg', 'CO₂ Emissions\nReduced'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlanceItem(dynamic icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _greenSurface,
            shape: BoxShape.circle,
            border: Border.all(color: _greenBorder),
          ),
          child: HugeIcon(icon: icon, color: _green, size: 20),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _green),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// Money saved vs market + the meals-goal progress bar — both from the summary.
  Widget _buildGoal(ImpactSummary s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _greenSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _greenBorder),
                ),
                child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedMoney01,
                    color: _green,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatMoney(s.moneySaved),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _green),
                    ),
                    Text('Saved for buyers vs market price',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Meals-served goal',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              Text('${formatCount(s.mealsServed)} / ${formatCount(s.mealsGoal)}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.goalProgress,
              minHeight: 10,
              backgroundColor: _greenSurface,
              valueColor: const AlwaysStoppedAnimation(_green),
            ),
          ),
          const SizedBox(height: 6),
          Text('${(s.goalProgress * 100).round()}% of the pilot goal reached',
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildCommunityImpact(ImpactSummary s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Impact',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _buildCommunityItem(
                HugeIcons.strokeRoundedUserMultiple,
                'Meals for Those in Need',
                'Your surplus food is reaching people who need it most.',
                formatCount(s.mealsServed),
                'Meals Provided',
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              _buildCommunityItem(
                HugeIcons.strokeRoundedStore01,
                'Supporting Local Vendors',
                'You\'re supporting local vendors and small businesses in your community.',
                '${s.activeVendors}',
                'Active Vendors',
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              _buildCommunityItem(
                HugeIcons.strokeRoundedFavourite,
                'Partnering with NGOs',
                'Together with community kitchens, we turn surplus into meals.',
                '${s.activeNgos}',
                'NGO Partners',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityItem(dynamic icon, String title, String desc,
      String statValue, String statLabel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _greenSurface,
              shape: BoxShape.circle,
              border: Border.all(color: _greenBorder),
            ),
            child: HugeIcon(icon: icon, color: _green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statValue,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: _green),
              ),
              const SizedBox(height: 2),
              Text(
                statLabel,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetImpact(ImpactSummary s) {
    final water = s.kgRescued * _waterPerKg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Planet Impact',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPlanetItem(
                  HugeIcons.strokeRoundedRecycle01,
                  '${formatCount(s.kgRescued)} kg',
                  'Food Waste Prevented',
                  'Keeping good food out of landfills',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlanetItem(
                  HugeIcons.strokeRoundedTree02,
                  '${formatCount(water)} L',
                  'Water Saved',
                  'Embedded water kept in the food system',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlanetItem(
                  HugeIcons.strokeRoundedLeaf02,
                  '${formatCount(s.co2SavedKg)} kg',
                  'CO₂ Emissions Reduced',
                  'Lowering our carbon footprint together',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanetItem(
      dynamic icon, String value, String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _greenSurface,
            shape: BoxShape.circle,
            border: Border.all(color: _greenBorder),
          ),
          child: HugeIcon(icon: icon, color: _green, size: 18),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _green),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// The pilot leaderboard — top contributors, straight from [ImpactData].
  Widget _buildLeaderboard(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final maxKg = entries.fold<double>(
        0, (m, e) => e.kg > m ? e.kg : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Contributors',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                _buildLeaderRow(entries[i], maxKg),
                if (i != entries.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderRow(LeaderboardEntry e, double maxKg) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _greenSurface,
            shape: BoxShape.circle,
          ),
          child: Text('${e.rank}',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: _greenDark)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ),
                  Text('${formatCount(e.kg)} kg',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _green)),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: maxKg <= 0 ? 0 : (e.kg / maxKg).clamp(0, 1).toDouble(),
                  minHeight: 6,
                  backgroundColor: _greenSurface,
                  valueColor: const AlwaysStoppedAnimation(_green),
                ),
              ),
              const SizedBox(height: 3),
              Text('${e.role} · ${formatCount(e.meals)} meals',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  /// Entry point to the read-only rescue network — the "Transform" leg where
  /// end-of-life surplus becomes meals through NGO kitchens.
  Widget _buildRescueCta(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/rescues'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _greenBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: _greenSurface,
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDeliveryTruck02,
                  color: _green,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Explore the rescue network',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _greenDark)),
                  const SizedBox(height: 2),
                  Text(
                      'See surplus routed to community kitchens & NGOs, live.',
                      style:
                          TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                ],
              ),
            ),
            HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: Colors.grey.shade500,
                size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _greenSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: _greenBorder,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedLeaf02,
              color: _green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proud of our impact!',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _greenDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'Small actions today, bigger change tomorrow.',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      );
}
