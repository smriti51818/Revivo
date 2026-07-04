import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';

/// Seeded demand insights for the seller. Post-deploy these are generated from
/// order history and Amazon Bedrock demand summaries; the copy here mirrors
/// that output so the screen is demoable offline.
class SellerInsightsScreen extends StatelessWidget {
  const SellerInsightsScreen({super.key});

  static const _insights = [
    (
      Icons.trending_up,
      'List leafy greens before noon',
      'Spinach and coriander sell ~2× faster when listed in the morning window.'
    ),
    (
      Icons.schedule,
      'Rescue-band moves fastest after 6 PM',
      'NGO kitchens pick up most rescue-priced produce in the evening.'
    ),
    (
      Icons.local_offer_outlined,
      'Small discounts clear use-soon stock',
      'A 20% cut on use-soon items clears them ~40% quicker with no waste.'
    ),
  ];

  static const _movers = [
    ('Roma Tomatoes', '128 kg', '+18%'),
    ('Baby Spinach', '96 kg', '+12%'),
    ('Bell Peppers', '74 kg', '+9%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const Text(
              'Insights',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sell smarter, waste less',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            _peakCard(),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Recommendations'),
            const SizedBox(height: AppSpacing.md),
            for (final i in _insights) ...[
              _insightCard(i.$1, i.$2, i.$3),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            const SectionHeader(title: 'Your top movers'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _movers.length; i++) ...[
                    _moverRow(_movers[i].$1, _movers[i].$2, _movers[i].$3),
                    if (i != _movers.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _peakCard() {
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
              const Icon(Icons.bolt, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                'Peak demand window',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '5 – 8 PM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hotels and kitchens buy the most surplus in the evening — list before 4 PM.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(IconData icon, String title, String body) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moverRow(String name, String kg, String trend) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.eco, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              name,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            kg,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              trend,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
