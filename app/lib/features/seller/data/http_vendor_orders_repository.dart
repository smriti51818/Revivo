import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../../../core/models/freshness.dart';
import '../../buyer/domain/order.dart';
import 'vendor_orders_repository.dart' show VendorOrdersRepository, orderStatusValue;

/// Live implementation: GET /orders/incoming (orders on this seller's listings).
class HttpVendorOrdersRepository implements VendorOrdersRepository {
  HttpVendorOrdersRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Order>> fetchIncoming() async {
    final res = await _api.get('/orders/incoming');
    final items = (res is Map ? res['orders'] as List? : null) ?? const [];
    return items
        .map((e) => _fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Order> advance(String orderId, OrderStatus status) async {
    final res = await _api.post(
        '/orders/$orderId/status', {'status': orderStatusValue(status)});
    return _fromJson((res['order'] as Map).cast<String, dynamic>());
  }

  Order _fromJson(Map<String, dynamic> j) {
    return Order(
      id: (j['id'] ?? '').toString(),
      vendorName: (j['vendorName'] ?? '').toString(),
      buyerName: (j['buyerName'] ?? 'Buyer').toString(),
      vegetable: (j['vegetable'] ?? '').toString(),
      quantityKg: asDouble(j['quantityKg']),
      pricePerKg: asDouble(j['pricePerKg']),
      marketPricePerKg: asDouble(j['marketPricePerKg']),
      band: FreshnessBand.fromValue(j['band']?.toString()),
      status: OrderStatus.fromValue(j['status']?.toString()),
      placedAt: epochToDate(j['createdAt']),
      // Buyer's post-pickup review, so the seller sees it on past orders.
      rating: j['rating'] == null ? null : asInt(j['rating']),
      ratingTags: (j['ratingTags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      ratingComment: (j['ratingComment'] ?? '').toString(),
    );
  }
}
