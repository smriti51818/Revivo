import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';

/// Help, FAQ, and food-safety (FSSAI) information — the trust/compliance page
/// referenced in the spec's safety model.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = <({String q, String a})>[
    (
      q: 'How is freshness decided?',
      a: 'Every listing has a live countdown from the vendor\'s purchase date, '
          'storage, and local temperature. It is shown as a band — Good, Use '
          'soon, or Rescue — never a false-precision percentage.'
    ),
    (
      q: 'Is the produce safe to eat?',
      a: 'Vendors list only produce they would eat themselves. Photos are '
          'AI-screened for visible defects and GPS-verified at the stall, and '
          'you pay on pickup after inspecting — so you only accept what looks right.'
    ),
    (
      q: 'How does the price work?',
      a: 'The price decays with freshness in real time. What you see on the '
          'countdown is exactly what you are charged — the riper it is, the '
          'lower the price.'
    ),
    (
      q: 'What if my order isn\'t right?',
      a: 'Decline at pickup, or open the order and tap "Report issue". Repeated '
          'quality mismatches lower a vendor\'s trust score.'
    ),
    (
      q: 'What happens to unsold surplus?',
      a: 'When produce reaches the Rescue band, it is offered to community '
          'kitchens and NGOs so it becomes a meal instead of waste.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & safety')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            _fssaiCard(),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Frequently asked'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _faqs.length; i++) ...[
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        childrenPadding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                        title: Text(_faqs[i].q,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_faqs[i].a,
                                style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                    if (i != _faqs.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              color: AppColors.surfaceAlt,
              child: Row(
                children: const [
                  HugeIcon(icon: HugeIcons.strokeRoundedCustomerSupport, color: AppColors.textSecondary),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Need a hand? Reach the Revivo pilot team at '
                      'support@revivo.demo — we respond the same evening.',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fssaiCard() {
    return AppCard(
      color: AppColors.primarySurface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge01, color: AppColors.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Food-safety first',
                    style: TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                  'Revivo aligns with FSSAI\'s Food Safety and Standards '
                  '(Recovery and Distribution of Surplus Food) Regulations, 2019, '
                  'and the Save Food, Share Food initiative. GPS-verified photos, '
                  'defect screening, and freshness bands document due diligence '
                  'on every listing.',
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
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
