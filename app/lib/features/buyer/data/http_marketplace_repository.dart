import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../../../core/discovery/vendor_directory.dart';
import '../../../core/models/freshness.dart';
import '../domain/offer.dart';
import '../domain/order.dart';
import 'marketplace_repository.dart';

/// Live implementation backed by the REST API:
/// GET /listings (market), GET /orders + POST /orders (buyer orders).
class HttpMarketplaceRepository implements MarketplaceRepository {
  HttpMarketplaceRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Offer>> fetchOffers() async {
    final res = await _api.get('/listings');
    final items = (res is Map ? res['listings'] as List? : null) ?? const [];
    return items
        .map((e) => _offerFromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<Order>> fetchOrders() async {
    final res = await _api.get('/orders');
    final items = (res is Map ? res['orders'] as List? : null) ?? const [];
    return items
        .map((e) => _orderFromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Order> placeOrder({
    required Offer offer,
    required double quantityKg,
    String pickupSlot = '',
    String paymentMethod = 'PICKUP',
  }) async {
    final res = await _api.post('/orders', {
      'listingId': offer.id,
      'quantityKg': quantityKg,
      'pickupSlot': pickupSlot,
      'paymentMethod': paymentMethod,
    });
    return _orderFromJson((res['order'] as Map).cast<String, dynamic>());
  }

  @override
  Future<Order> rateOrder({
    required String orderId,
    required int stars,
    List<String> tags = const [],
    String comment = '',
  }) async {
    final res = await _api.post('/orders/$orderId/rate', {
      'stars': stars,
      'tags': tags,
      'comment': comment,
    });
    return _orderFromJson((res['order'] as Map).cast<String, dynamic>());
  }

  Offer _offerFromJson(Map<String, dynamic> j) {
    final expiry = j['expiryEpoch'];
    final vendorName = (j['vendorName'] ?? 'Vendor').toString();
    // Backend distance isn't wired yet; fall back to the vendor directory so
    // proximity is consistent across the market, radar, and vendor pages.
    final apiDistance = asDouble(j['distanceKm']);
    return Offer(
      id: (j['id'] ?? '').toString(),
      vendorName: vendorName,
      vegetable: (j['vegetable'] ?? '').toString(),
      availableKg: asDouble(j['quantityKg']),
      marketPrice: asDouble(j['basePrice']),
      offerPrice: asDouble(j['recommendedPrice']),
      band: FreshnessBand.fromValue(j['band']?.toString()),
      timeRange: (j['timeRange'] ?? '').toString(),
      distanceKm:
          apiDistance > 0 ? apiDistance : vendorInfo(vendorName).distanceKm,
      imageUrl: (j['imageUrl'] ?? '').toString(),
      expiresAt: expiry is num ? epochToDate(expiry) : null,
      totalHours: j['totalHours'] == null ? null : asDouble(j['totalHours']),
    );
  }

  Order _orderFromJson(Map<String, dynamic> j) {
    return Order(
      id: (j['id'] ?? '').toString(),
      vendorName: (j['vendorName'] ?? 'Vendor').toString(),
      vegetable: (j['vegetable'] ?? '').toString(),
      quantityKg: asDouble(j['quantityKg']),
      pricePerKg: asDouble(j['pricePerKg']),
      marketPricePerKg: asDouble(j['marketPricePerKg']),
      band: FreshnessBand.fromValue(j['band']?.toString()),
      status: OrderStatus.fromValue(j['status']?.toString()),
      imagePath: (j['imageUrl'] ?? '').toString().isEmpty
          ? null
          : (j['imageUrl']).toString(),
      placedAt: epochToDate(j['createdAt']),
      pickupSlot: (j['pickupSlot'] ?? '').toString(),
      paymentMethod: (j['paymentMethod'] ?? 'PICKUP').toString(),
      rating: (j['rating'] as num?)?.toInt(),
      ratingTags: [
        for (final t in (j['ratingTags'] as List?) ?? const []) t.toString(),
      ],
      ratingComment: (j['ratingComment'] ?? '').toString(),
    );
  }
}
