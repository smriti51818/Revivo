import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import 'application/insights_providers.dart';
import 'domain/seller_insights.dart';

/// Insights computed on AWS from the seller's real listings + orders, with
/// recommendations from Amazon Bedrock (Claude) — or a data-grounded fallback.
class SellerInsightsScreen extends ConsumerWidget {
  const SellerInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sellerInsightsProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(sellerInsightsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              const Text('Insights',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('From your listings & orders',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(child: Text('Could not load insights: $e')),
                ),
                data: _content,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(SellerInsightsData d) {
    if (!d.hasActivity) {
      return const Padding(
        padding: EdgeInsets.only(top: 56),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.insights_outlined, size: 40, color: AppColors.textMuted),
              SizedBox(height: AppSpacing.md),
              Text('No insights yet',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              SizedBox(height: 2),
              Text('List surplus and make sales to unlock insights',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _metric('Revenue', formatMoney(d.revenue)),
            const SizedBox(width: AppSpacing.md),
            _metric('Sold', formatKg(d.soldKg)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _metric('Active listings', '${d.activeListings}'),
            const SizedBox(width: AppSpacing.md),
            _metric('Orders', '${d.orders}'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (d.peakHour != null) ...[
          _peakCard(d.peakHour!),
          const SizedBox(height: AppSpacing.xl),
        ],
        Row(
          children: [
            SectionHeader(
                title: d.aiPowered ? 'AI recommendations' : 'Recommendations'),
            if (d.aiPowered) ...[
              const SizedBox(width: 8),
              _aiBadge(),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (d.recommendations.isEmpty)
          const Text('No recommendations yet.',
              style: TextStyle(color: AppColors.textSecondary))
        else
          for (final r in d.recommendations) ...[
            _insightCard(r),
            const SizedBox(height: AppSpacing.md),
          ],
        if (d.movers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const SectionHeader(title: 'Your top movers'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < d.movers.length; i++) ...[
                  _moverRow(d.movers[i]),
                  if (i != d.movers.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }

  Widget _aiBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
            SizedBox(width: 3),
            Text('Bedrock',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                )),
          ],
        ),
      );

  Widget _peakCard(int hour) {
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
              Text('Peak demand window',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_hourLabel(hour),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1,
              )),
          const SizedBox(height: 4),
          Text('Most of your orders land here — list a few hours before.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _insightCard(InsightRec rec) {
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
            child: const Icon(Icons.tips_and_updates_outlined,
                size: 20, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(rec.body,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moverRow(MoverRow m) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.eco, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(m.vegetable,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(formatKg(m.kg),
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(formatMoney(m.revenue),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                )),
          ),
        ],
      ),
    );
  }

  String _hourLabel(int hour) {
    String fmt(int h) {
      final suffix = h < 12 ? 'AM' : 'PM';
      final base = h % 12 == 0 ? 12 : h % 12;
      return '$base $suffix';
    }

    return '${fmt(hour)} – ${fmt((hour + 3) % 24)}';
  }
}
