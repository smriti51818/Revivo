import '../../../core/freshness/freshness_estimator.dart';
import '../../../core/models/freshness.dart';
import '../domain/freshness_analysis.dart';
import '../domain/listing.dart';

/// Data source for listings. The in-memory implementation seeds the demo and
/// is swapped for an HTTP implementation against the live API after deploy.
abstract class ListingsRepository {
  Future<List<Listing>> fetchListings();
  Future<Listing> createListing(Listing draft);

  /// Freshness analysis for a draft (band, time window, fair price).
  Future<FreshnessAnalysis> analyze({
    required String vegetable,
    required double basePrice,
    required double quantityKg,
    required StorageCondition storage,
    required DateTime purchasedAt,
  });
}

class InMemoryListingsRepository implements ListingsRepository {
  final List<Listing> _items = [
    Listing(
      id: 'lst_seed_tomato',
      vegetable: 'Heirloom Tomatoes',
      quantityKg: 15,
      basePrice: 30,
      recommendedPrice: 30,
      band: FreshnessBand.good,
      timeRange: '~14-18 h',
      storage: StorageCondition.room,
      organic: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Listing(
      id: 'lst_seed_pepper',
      vegetable: 'Bell Pepper Mix',
      quantityKg: 2.4,
      basePrice: 45,
      recommendedPrice: 31.5,
      band: FreshnessBand.useSoon,
      timeRange: '~8-10 h',
      storage: StorageCondition.room,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Listing(
      id: 'lst_seed_carrot',
      vegetable: 'Garden Carrots',
      quantityKg: 28,
      basePrice: 35,
      recommendedPrice: 35,
      band: FreshnessBand.good,
      timeRange: '~4-5 days',
      storage: StorageCondition.refrigerated,
      createdAt: DateTime.now().subtract(const Duration(hours: 9)),
    ),
    Listing(
      id: 'lst_seed_spinach',
      vegetable: 'Baby Spinach',
      quantityKg: 3,
      basePrice: 20,
      recommendedPrice: 8,
      band: FreshnessBand.rescue,
      timeRange: '~2-3 h',
      storage: StorageCondition.room,
      createdAt: DateTime.now().subtract(const Duration(hours: 11)),
    ),
  ];

  @override
  Future<List<Listing>> fetchListings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }

  @override
  Future<Listing> createListing(Listing draft) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _items.insert(0, draft);
    return draft;
  }

  @override
  Future<FreshnessAnalysis> analyze({
    required String vegetable,
    required double basePrice,
    required double quantityKg,
    required StorageCondition storage,
    required DateTime purchasedAt,
  }) async {
    // Offline mode only: mirror the server engine locally so the demo works.
    await Future.delayed(const Duration(milliseconds: 400));
    final est = estimateFreshness(
      vegetable: vegetable,
      purchasedAt: purchasedAt,
      storage: storage.value,
    );
    return FreshnessAnalysis(
      band: est.band,
      timeRange: est.timeRange,
      recommendedPrice:
          double.parse((basePrice * est.priceFactor).toStringAsFixed(2)),
    );
  }
}
