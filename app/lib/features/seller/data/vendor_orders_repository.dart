import '../../../core/models/freshness.dart';
import '../../buyer/domain/order.dart';

/// Orders placed against this seller's listings (the seller's incoming queue).
/// Reuses the shared [Order] entity — the same order the buyer tracks, seen
/// from the vendor's side. Swapped for the HTTP implementation once live.
abstract class VendorOrdersRepository {
  Future<List<Order>> fetchIncoming();

  /// Vendor manually advances an order's fulfilment (mark ready / handed over).
  Future<Order> advance(String orderId, OrderStatus status);
}

/// Mock incoming orders for offline/demo mode.
class InMemoryVendorOrdersRepository implements VendorOrdersRepository {
  List<Order>? _items;

  @override
  Future<List<Order>> fetchIncoming() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _items ??= _seed();
  }

  @override
  Future<Order> advance(String orderId, OrderStatus status) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final list = _items ??= _seed();
    final idx = list.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw StateError('Order $orderId not found');
    final updated = list[idx].copyWith(status: status);
    list[idx] = updated;
    return updated;
  }

  List<Order> _seed() {
    return [
      Order(
        id: 'ord_1',
        vendorName: 'You',
        buyerName: 'Hotel Ashok',
        vegetable: 'Tomato',
        quantityKg: 6,
        pricePerKg: 28,
        marketPricePerKg: 40,
        band: FreshnessBand.useSoon,
        status: OrderStatus.preparing,
        placedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      Order(
        id: 'ord_2',
        vendorName: 'You',
        buyerName: 'Sri Krishna Mess',
        vegetable: 'Spinach',
        quantityKg: 3,
        pricePerKg: 12,
        marketPricePerKg: 30,
        band: FreshnessBand.rescue,
        status: OrderStatus.readyForPickup,
        placedAt: DateTime.now().subtract(const Duration(minutes: 24)),
      ),
      Order(
        id: 'ord_3',
        vendorName: 'You',
        buyerName: 'Adyar Ananda Bhavan',
        vegetable: 'Carrot',
        quantityKg: 10,
        pricePerKg: 38,
        marketPricePerKg: 45,
        band: FreshnessBand.good,
        status: OrderStatus.completed,
        placedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }
}

/// Maps an [OrderStatus] to the backend status string the API expects.
String orderStatusValue(OrderStatus status) => switch (status) {
      OrderStatus.confirmed => 'CONFIRMED',
      OrderStatus.preparing => 'PREPARING',
      OrderStatus.readyForPickup => 'READY_FOR_PICKUP',
      OrderStatus.completed => 'COMPLETED',
    };
