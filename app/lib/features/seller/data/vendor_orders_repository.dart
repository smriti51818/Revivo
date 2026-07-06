import '../../../core/models/freshness.dart';
import '../../buyer/domain/order.dart';

/// Orders placed against this seller's listings (the seller's incoming queue).
/// Reuses the shared [Order] entity — the same order the buyer tracks, seen
/// from the vendor's side. Swapped for the HTTP implementation once live.
abstract class VendorOrdersRepository {
  Future<List<Order>> fetchIncoming();
}

/// Mock incoming orders for offline/demo mode.
class InMemoryVendorOrdersRepository implements VendorOrdersRepository {
  @override
  Future<List<Order>> fetchIncoming() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Order(
        id: 'ord_1',
        vendorName: 'You',
        buyerName: 'Hotel Ashok',
        vegetable: 'Tomatoes',
        quantityKg: 6,
        pricePerKg: 22,
        marketPricePerKg: 32,
        band: FreshnessBand.useSoon,
        status: OrderStatus.preparing,
        placedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      Order(
        id: 'ord_2',
        vendorName: 'You',
        buyerName: 'Green Leaf Cafe',
        vegetable: 'Baby Spinach',
        quantityKg: 3,
        pricePerKg: 18,
        marketPricePerKg: 26,
        band: FreshnessBand.rescue,
        status: OrderStatus.readyForPickup,
        placedAt: DateTime.now().subtract(const Duration(minutes: 24)),
      ),
      Order(
        id: 'ord_3',
        vendorName: 'You',
        buyerName: 'Sunrise Kitchen',
        vegetable: 'Carrots',
        quantityKg: 10,
        pricePerKg: 20,
        marketPricePerKg: 28,
        band: FreshnessBand.good,
        status: OrderStatus.completed,
        placedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }
}
