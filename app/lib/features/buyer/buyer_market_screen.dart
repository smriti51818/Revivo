import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/discovery/produce_category.dart';
import '../../core/models/freshness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/motion.dart';
import 'application/favorites_providers.dart';
import 'application/marketplace_providers.dart';
import 'domain/offer.dart';
import 'widgets/cart_bar.dart';
import 'widgets/offer_card.dart';

enum _MarketFilter {
  all('All'),
  rescue('Rescue deals'),
  saved('Saved'),
  organic('Organic'),
  nearby('Nearby');

  const _MarketFilter(this.label);
  final String label;
}

class BuyerMarketScreen extends ConsumerStatefulWidget {
  const BuyerMarketScreen({super.key});

  @override
  ConsumerState<BuyerMarketScreen> createState() => _BuyerMarketScreenState();
}

class _BuyerMarketScreenState extends ConsumerState<BuyerMarketScreen> {
  String _query = '';
  _MarketFilter _filter = _MarketFilter.all;
  ProduceCategory _category = ProduceCategory.all;
  bool _isGridView = false;

  List<Offer> _apply(List<Offer> offers) {
    var list = offers;
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((o) =>
              o.vegetable.toLowerCase().contains(q) ||
              o.vendorName.toLowerCase().contains(q))
          .toList();
    }
    if (_category != ProduceCategory.all) {
      list = list.where((o) => matchesCategory(_category, o.vegetable)).toList();
    }
    list = switch (_filter) {
      _MarketFilter.all => list,
      _MarketFilter.rescue =>
        list.where((o) => o.liveBand() == FreshnessBand.rescue).toList(),
      _MarketFilter.saved => () {
          final favs = ref.read(favoritesProvider);
          return list.where((o) => favs.contains(o.id)).toList();
        }(),
      _MarketFilter.organic => list.where((o) => o.organic).toList(),
      _MarketFilter.nearby => [...list]
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)),
    };
    return list;
  }



  static const _hpad = EdgeInsets.symmetric(horizontal: AppSpacing.screen);

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(offersProvider);
    ref.watch(favoritesProvider);

    return Scaffold(
      bottomNavigationBar: const CartBar(),
      body: Column(
        children: [
          _buildGreenHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(offersProvider.future),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                children: [
                  offers.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen, 32, AppSpacing.screen, 0),
                      child: Center(child: Text('Could not load offers: $e')),
                    ),
                    data: (all) => _loaded(context, all),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Market',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {},
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation01,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Indiranagar, Bengaluru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 2),
                          HugeIcon(
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
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: Colors.white,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSlidersHorizontal,
                    color: Colors.white,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      hintText: 'Search vegetables, sellers...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _query = ''),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F8A5F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: const Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSlidersHorizontal,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loaded(BuildContext context, List<Offer> all) {
    final list = _apply(all);
    final searching = _query.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        _categoryRow(),
        const SizedBox(height: AppSpacing.md),
        _sortAndFilterRow(),
        const SizedBox(height: AppSpacing.md),
        if (!searching) ...[
          Padding(
            padding: _hpad,
            child: _buildEndingSoonPromo(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Padding(
          padding: _hpad,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${list.length} listings near you',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Just updated',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (list.isEmpty)
          _empty()
        else
          Padding(
            padding: _hpad,
            child: Column(
              children: [
                for (var i = 0; i < list.length; i++) ...[
                  FadeSlideIn(
                    delay: Duration(milliseconds: i < 8 ? i * 45 : 0),
                    child: OfferCard(
                      offer: list[i],
                      onTap: () =>
                          context.push('/buyer/product', extra: list[i]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _categoryRow() {
    final categories = [
      (ProduceCategory.all, 'All', HugeIcons.strokeRoundedGridView),
      (ProduceCategory.leafy, 'Leafy', HugeIcons.strokeRoundedLeaf02),
      (ProduceCategory.roots, 'Roots', HugeIcons.strokeRoundedPackage),
      (ProduceCategory.fruiting, 'Gourd', HugeIcons.strokeRoundedApple),
      (ProduceCategory.herbs, 'Others', HugeIcons.strokeRoundedMoreHorizontal),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: _hpad,
      child: Row(
        children: [
          for (final cat in categories) ...[
            GestureDetector(
              onTap: () => setState(() => _category = cat.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _category == cat.$1
                      ? AppColors.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _category == cat.$1
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: cat.$3,
                      color: _category == cat.$1
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _category == cat.$1
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _sortAndFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: _hpad,
      child: Row(
        children: [
          Text(
            'Sort by ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Text(
                  'Ending soon',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  color: AppColors.primaryDark,
                  size: 14,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Distance ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Text(
                  'Nearby',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  color: AppColors.primaryDark,
                  size: 14,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'View ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isGridView = true),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isGridView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedGridView,
                      color: _isGridView ? AppColors.primary : AppColors.textMuted,
                      size: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isGridView = false),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: !_isGridView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedListView,
                      color: !_isGridView ? AppColors.primary : AppColors.textMuted,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndingSoonPromo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDFBF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3F2E4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedFlash,
              color: Colors.white,
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ending soon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Grab the best deals before time runs out!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            color: AppColors.textMuted,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedStore01, size: 48, color: AppColors.borderStrong),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No surplus matches your filter',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      );
}
