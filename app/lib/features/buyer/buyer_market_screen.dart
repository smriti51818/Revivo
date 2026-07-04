import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/freshness.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'application/marketplace_providers.dart';
import 'domain/offer.dart';
import 'widgets/offer_card.dart';

enum _MarketFilter {
  all('All'),
  rescue('Rescue deals'),
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
    list = switch (_filter) {
      _MarketFilter.all => list,
      _MarketFilter.rescue =>
        list.where((o) => o.band == FreshnessBand.rescue).toList(),
      _MarketFilter.organic => list.where((o) => o.organic).toList(),
      _MarketFilter.nearby => [...list]
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)),
    };
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(offersProvider);
    final name = ref.watch(sessionProvider)?.name ?? 'Buyer';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(offersProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              _Header(name: name),
              const SizedBox(height: AppSpacing.lg),
              _searchField(),
              const SizedBox(height: AppSpacing.md),
              _filterRow(),
              const SizedBox(height: AppSpacing.lg),
              offers.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(child: Text('Could not load offers: $e')),
                ),
                data: (all) {
                  final list = _apply(all);
                  if (list.isEmpty) return _empty();
                  return Column(
                    children: [
                      for (final offer in list) ...[
                        OfferCard(
                          offer: offer,
                          onTap: () =>
                              context.push('/buyer/product', extra: offer),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search, size: 20),
        hintText: 'Search vegetables or vendors',
      ),
    );
  }

  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
        padding: const EdgeInsets.only(top: 56),
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

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

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
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}
