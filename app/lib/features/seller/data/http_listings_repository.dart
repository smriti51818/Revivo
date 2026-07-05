import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../../../core/models/freshness.dart';
import '../domain/listing.dart';
import 'listings_repository.dart';

/// Live implementation backed by the REST API:
/// GET /listings/mine (seller dashboard) and POST /listings (publish).
class HttpListingsRepository implements ListingsRepository {
  HttpListingsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Listing>> fetchListings() async {
    final res = await _api.get('/listings/mine');
    final items = (res is Map ? res['listings'] as List? : null) ?? const [];
    return items
        .map((e) => _fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Listing> createListing(Listing draft) async {
    final purchased = draft.purchasedAt ?? draft.createdAt;
    final res = await _api.post('/listings', {
      'vegetable': draft.vegetable,
      'quantityKg': draft.quantityKg,
      'basePrice': draft.basePrice,
      'storage': draft.storage.value,
      'purchasedAt': purchased.millisecondsSinceEpoch ~/ 1000,
      'tempC': draft.tempC ?? 28,
      'imageKey': '',
    });
    return _fromJson((res['listing'] as Map).cast<String, dynamic>());
  }

  Listing _fromJson(Map<String, dynamic> j) {
    return Listing(
      id: (j['id'] ?? '').toString(),
      vegetable: (j['vegetable'] ?? '').toString(),
      quantityKg: asDouble(j['quantityKg']),
      basePrice: asDouble(j['basePrice']),
      recommendedPrice: asDouble(j['recommendedPrice']),
      band: FreshnessBand.fromValue(j['band']?.toString()),
      timeRange: (j['timeRange'] ?? '').toString(),
      storage: StorageCondition.fromValue(j['storage']?.toString()),
      createdAt: epochToDate(j['createdAt']),
    );
  }
}
