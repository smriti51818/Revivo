import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/discovery/vendor_directory.dart';
import '../../core/format.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/location_picker_sheet.dart';
import '../../core/widgets/motion.dart';
import 'application/listings_providers.dart';
import 'application/vendor_orders_providers.dart';
import 'domain/listing.dart';
import 'widgets/listing_card.dart';

void _confirmDelete(BuildContext context, WidgetRef ref, Listing listing) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete listing?'),
      content: Text(
        '"${listing.vegetable}" will be permanently removed. '
        'Hotels and buyers who saved this offer will no longer see it.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ref.read(listingsProvider.notifier).deleteListing(listing.id);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsProvider);
    final name = ref.watch(sessionProvider)?.name ?? 'Vendor';
    final location = vendorInfo(name).areaLabel;

    // Real, derivable summary stats — no fabricated numbers.
    final items = listingsAsync.valueOrNull ?? const <Listing>[];
    final activeCount = items.length;
    final atRiskCount = items.where((l) => l.atRisk()).length;
    final potentialValue =
        items.fold<double>(0, (sum, l) => sum + l.liveValue());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(
            name: name,
            location: location,
            activeCount: activeCount,
            atRiskCount: atRiskCount,
            potentialValue: potentialValue,
            onTapLocation: () => showLocationPicker(context, ref),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.read(vendorOrdersProvider.notifier).reload();
                ref.invalidate(listingsProvider);
                await ref.read(listingsProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
                children: [
                  _SectionHeader(
                    title: 'Your inventory',
                    count: activeCount,
                    onViewAll: () => context.push('/seller/listings'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  listingsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 56),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    ),
                    error: (e, _) => _ErrorState(message: '$e'),
                    data: (list) => list.isEmpty
                        ? const _EmptyState()
                        : Column(
                            children: [
                              for (var i = 0; i < list.length; i++) ...[
                                FadeSlideIn(
                                  delay: Duration(milliseconds: 60 * i),
                                  child: ListingCard(
                                    listing: list[i],
                                    onUpdateStock: () => context.push(
                                        '/seller/update-stock',
                                        extra: list[i]),
                                    onEdit: () => context.push(
                                        '/seller/update-stock',
                                        extra: list[i]),
                                    onDelete: () => _confirmDelete(
                                        context, ref, list[i]),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green rounded header with greeting, location, and a floating stats strip —
/// the "partner app" home hero.
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.location,
    required this.activeCount,
    required this.atRiskCount,
    required this.potentialValue,
    required this.onTapLocation,
  });

  final String name;
  final String location;
  final int activeCount;
  final int atRiskCount;
  final double potentialValue;
  final VoidCallback onTapLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: AppSpacing.lg,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: onTapLocation,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation01,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowDown01,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                        icon: HugeIcons.strokeRoundedStore02,
                        color: Colors.white,
                        size: 13),
                    SizedBox(width: 5),
                    Text(
                      'Seller',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatsStrip(
            activeCount: activeCount,
            atRiskCount: atRiskCount,
            potentialValue: potentialValue,
          ),
        ],
      ),
    );
  }
}

/// A single white card holding the three headline stats with hairline dividers.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.activeCount,
    required this.atRiskCount,
    required this.potentialValue,
  });

  final int activeCount;
  final int atRiskCount;
  final double potentialValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _Stat(
            icon: HugeIcons.strokeRoundedPackage,
            iconColor: AppColors.primary,
            value: '$activeCount',
            label: 'Active',
          ),
          const _StatDivider(),
          _Stat(
            icon: HugeIcons.strokeRoundedAlert02,
            iconColor:
                atRiskCount > 0 ? AppColors.warning : AppColors.textMuted,
            value: '$atRiskCount',
            label: 'At risk',
          ),
          const _StatDivider(),
          _Stat(
            icon: HugeIcons.strokeRoundedRupee,
            iconColor: AppColors.primary,
            value: '₹${formatCount(potentialValue)}',
            label: 'Potential',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final dynamic icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          HugeIcon(icon: icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: AppColors.border,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onViewAll,
  });

  final String title;
  final int count;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        const Spacer(),
        GestureDetector(
          onTap: onViewAll,
          behavior: HitTestBehavior.opaque,
          child: const Row(
            children: [
              Text(
                'View all',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 2),
              HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 13,
                  color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedPackage,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No listings yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap + to add your first listing',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 34,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Could not load listings',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
