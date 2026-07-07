import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/discovery/produce_category.dart';
import '../../core/format.dart';
import '../../core/models/freshness.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/live_clock_chip.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/section_header.dart';
import 'application/cart_providers.dart';
import 'application/favorites_providers.dart';
import 'application/marketplace_providers.dart';
import 'domain/offer.dart';
import 'widgets/cart_bar.dart';
import 'widgets/live_rescue_rail.dart';
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

  /// Ending-soon deals for the live rail: Use Soon + Rescue bands, most urgent
  /// first. Falls back to nothing when the market is all fresh.
  List<Offer> _endingSoon(List<Offer> offers) {
    final list = offers
        .where((o) => o.liveBand() != FreshnessBand.good && !o.isExpired())
        .toList()
      ..sort((a, b) {
        final ax = a.expiresAt, bx = b.expiresAt;
        if (ax == null || bx == null) return 0;
        return ax.compareTo(bx);
      });
    return list;
  }

  static const _hpad = EdgeInsets.symmetric(horizontal: AppSpacing.screen);

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(offersProvider);
    final name = ref.watch(sessionProvider)?.name ?? 'Buyer';
    ref.watch(favoritesProvider); // re-filter the Saved tab as hearts toggle

    return Scaffold(
      bottomNavigationBar: const CartBar(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(offersProvider.future),
          child: ListView(
            padding: const EdgeInsets.only(
                top: AppSpacing.screen, bottom: AppSpacing.xl),
            children: [
              Padding(padding: _hpad, child: _Header(name: name)),
              const SizedBox(height: AppSpacing.md),
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
    );
  }

  Widget _loaded(BuildContext context, List<Offer> all) {
    final ending = _endingSoon(all);
    final list = _apply(all);
    final vendors = all.map((o) => o.vendorName).toSet().length;
    final kg = all.fold<double>(0, (s, o) => s + o.availableKg);
    final searching = _query.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _hpad,
          child: _LiveStrip(dealCount: ending.length, kg: kg, vendors: vendors),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: _hpad,
          child: _RadarEntry(count: all.where((o) => !o.isExpired()).length),
        ),
        if (ending.isNotEmpty && !searching) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: _hpad,
            child: SectionHeader(title: 'Ending soon · ${ending.length} live'),
          ),
          const SizedBox(height: AppSpacing.sm),
          LiveRescueRail(
            offers: ending,
            onTap: (o) => context.push('/buyer/product', extra: o),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Padding(padding: _hpad, child: _searchField()),
        const SizedBox(height: AppSpacing.md),
        _categoryRow(),
        const SizedBox(height: AppSpacing.sm),
        _filterRow(),
        const SizedBox(height: AppSpacing.lg),
        if (list.isEmpty)
          _empty()
        else
          Padding(
            padding: _hpad,
            child: Column(
              children: [
                for (var i = 0; i < list.length; i++) ...[
                  FadeSlideIn(
                    // Stagger the first screenful; later cards appear instantly.
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

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 20),
        hintText: 'Search vegetables or vendors',
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _query = ''),
              ),
      ),
    );
  }

  Widget _categoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: _hpad,
      child: Row(
        children: [
          for (final c in ProduceCategory.values) ...[
            ChoiceChip(
              label: Text(c.label),
              selected: _category == c,
              onSelected: (_) => setState(() => _category = c),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _category == c ? Colors.white : AppColors.textSecondary,
              ),
              backgroundColor: AppColors.surfaceAlt,
              side: BorderSide.none,
              showCheckmark: false,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: _hpad,
      child: Row(
        children: [
          for (final f in _MarketFilter.values) ...[
            ChoiceChip(
              label: Text(f.label),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: AppColors.primarySurface,
              showCheckmark: false,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.storefront_outlined,
                  size: 40, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No surplus matches your filter',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}

/// Thin strip under the header: the live clock + a one-line market summary.
class _LiveStrip extends StatelessWidget {
  const _LiveStrip(
      {required this.dealCount, required this.kg, required this.vendors});

  final int dealCount;
  final double kg;
  final int vendors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const LiveClockChip(),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            vendors == 0
                ? 'Surplus updates in real time'
                : '${formatKg(kg)} from $vendors ${vendors == 1 ? 'vendor' : 'vendors'} today',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Discoverable entry into the rescue radar.
class _RadarEntry extends StatelessWidget {
  const _RadarEntry({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => context.push('/buyer/map'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.radar, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rescue radar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    Text('See $count surplus lots near your hotel',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11.5)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 22),
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
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    'Coimbatore · surplus nearby',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _CartButton(count: cartCount),
      ],
    );
  }
}

/// Cart icon with a live item-count badge.
class _CartButton extends StatelessWidget {
  const _CartButton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => context.push('/buyer/cart'),
          icon: const Icon(Icons.shopping_cart_outlined),
          color: AppColors.textSecondary,
        ),
        Positioned(
          right: 4,
          top: 4,
          child: AnimatedScale(
            scale: count > 0 ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
