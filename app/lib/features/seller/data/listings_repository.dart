import '../../../core/freshness/freshness_estimator.dart';
import '../../../core/models/freshness.dart';
import '../domain/freshness_analysis.dart';
import '../domain/listing.dart';

/// Data source for listings. The in-memory implementation seeds the demo and
/// is swapped for an HTTP implementation against the live API after deploy.
abstract class ListingsRepository {
  Future<List<Listing>> fetchListings();
  Future<Listing> createListing(Listing draft);

  /// Updates a listing's available stock (quantity), and optionally replaces its
  /// photo ([imageKey]). Owner-only server-side.
  Future<Listing> updateStock(String id, double quantityKg,
      {String? imageKey});

  /// Deletes a listing. Buyers who saved it will no longer see it.
  Future<void> deleteListing(String id);

  /// Uploads a captured photo to S3, returning its object key (or '' on
  /// failure). Done at capture time so Rekognition can read it.
  Future<String> uploadPhoto(String path);

  /// Amazon Rekognition guess of the vegetable in an uploaded photo, or null.
  Future<String?> identify(String imageKey);

  /// Server-side freshness analysis for a draft. Price is derived from the
  /// vegetable's market rate — the seller never types a price.
  Future<FreshnessAnalysis> analyze({
    required String vegetable,
    required double quantityKg,
    required StorageCondition storage,
    required DateTime purchasedAt,
  });
}

class InMemoryListingsRepository implements ListingsRepository {
  final List<Listing> _items = [
    Listing(
      id: 'lst_seed_tomato',
      vegetable: 'Tomato',
      quantityKg: 12,
      basePrice: 40,
      recommendedPrice: 40,
      band: FreshnessBand.good,
      timeRange: '~14-18 h',
      storage: StorageCondition.room,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Listing(
      id: 'lst_seed_carrot',
      vegetable: 'Carrot',
      quantityKg: 28,
      basePrice: 45,
      recommendedPrice: 45,
      band: FreshnessBand.good,
      timeRange: '~4-5 days',
      storage: StorageCondition.refrigerated,
      createdAt: DateTime.now().subtract(const Duration(hours: 9)),
    ),
    Listing(
      id: 'lst_seed_spinach',
      vegetable: 'Spinach',
      quantityKg: 5,
      basePrice: 30,
      recommendedPrice: 21,
      band: FreshnessBand.useSoon,
      timeRange: '~8-10 h',
      storage: StorageCondition.room,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Listing(
      id: 'lst_seed_coriander',
      vegetable: 'Coriander',
      quantityKg: 3,
      basePrice: 40,
      recommendedPrice: 16,
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
  Future<void> deleteListing(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _items.removeWhere((l) => l.id == id);
  }

  @override
  Future<Listing> updateStock(String id, double quantityKg,
      {String? imageKey}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final idx = _items.indexWhere((l) => l.id == id);
    if (idx == -1) throw StateError('Listing $id not found');
    // Offline, [imageKey] is the picked file path — show it as the image.
    final updated = _items[idx].copyWith(
      quantityKg: quantityKg,
      imagePath: (imageKey != null && imageKey.isNotEmpty) ? imageKey : null,
    );
    _items[idx] = updated;
    return updated;
  }

  @override
  Future<String> uploadPhoto(String path) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return path; // offline: reuse the local path so the photo still displays
  }

  @override
  Future<String?> identify(String imageKey) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return null; // offline: no Rekognition — seller picks manually
  }

  @override
  Future<FreshnessAnalysis> analyze({
    required String vegetable,
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
    const market = 40.0; // offline placeholder market rate
    return FreshnessAnalysis(
      band: est.band,
      timeRange: est.timeRange,
      marketPrice: market,
      recommendedPrice:
          double.parse((market * est.priceFactor).toStringAsFixed(2)),
    );
  }
}
