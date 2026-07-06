import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../../../core/models/freshness.dart';
import '../../buyer/domain/order.dart';
import 'vendor_orders_repository.dart';

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
    );
  }
}
