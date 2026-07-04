import '../../../core/models/freshness.dart';
import '../domain/offer.dart';
import '../domain/order.dart';

/// Data source for the buyer marketplace. The in-memory implementation seeds a
/// realistic demo; it is swapped for an HTTP implementation against the live
/// API (GSI2 STATUS#ACTIVE query) after deploy.
abstract class MarketplaceRepository {
  Future<List<Offer>> fetchOffers();
  Future<List<Order>> fetchOrders();
  Future<Order> placeOrder({required Offer offer, required double quantityKg});
}

class InMemoryMarketplaceRepository implements MarketplaceRepository {
  final List<Offer> _offers = [
    const Offer(
      id: 'off_tomato',
      vendorName: 'GreenLeaf Farms',
      vegetable: 'Roma Tomatoes',
      availableKg: 12,
      marketPrice: 40,
      offerPrice: 34,
      band: FreshnessBand.good,
      timeRange: '~14-18 h',
      distanceKm: 1.2,
      organic: true,
    ),
    const Offer(
      id: 'off_pepper',
      vendorName: 'Anna Vegetable Stall',
      vegetable: 'Bell Pepper Mix',
      availableKg: 6,
      marketPrice: 60,
      offerPrice: 42,
      band: FreshnessBand.useSoon,
      timeRange: '~8-10 h',
      distanceKm: 2.1,
    ),
    const Offer(
      id: 'off_spinach',
      vendorName: 'Kovai Fresh Mart',
      vegetable: 'Baby Spinach',
      availableKg: 4,
      marketPrice: 30,
      offerPrice: 12,
      band: FreshnessBand.rescue,
      timeRange: '~2-3 h',
      distanceKm: 0.8,
    ),
    const Offer(
      id: 'off_carrot',
      vendorName: 'Sunrise Organics',
      vegetable: 'Garden Carrots',
      availableKg: 20,
      marketPrice: 45,
      offerPrice: 38,
      band: FreshnessBand.good,
      timeRange: '~4-5 days',
      distanceKm: 3.4,
      organic: true,
    ),
    const Offer(
      id: 'off_cauliflower',
      vendorName: 'RS Traders',
      vegetable: 'Cauliflower',
      availableKg: 9,
      marketPrice: 35,
      offerPrice: 24,
      band: FreshnessBand.useSoon,
      timeRange: '~10-12 h',
      distanceKm: 1.7,
    ),
    const Offer(
      id: 'off_beans',
      vendorName: 'Daily Greens',
      vegetable: 'French Beans',
      availableKg: 5,
      marketPrice: 50,
      offerPrice: 20,
      band: FreshnessBand.rescue,
      timeRange: '~3-4 h',
      distanceKm: 2.9,
    ),
  ];

  final List<Order> _orders = [
    Order(
      id: 'ord_seed_tomato',
      vendorName: 'GreenLeaf Farms',
      vegetable: 'Roma Tomatoes',
      quantityKg: 10,
      pricePerKg: 34,
      marketPricePerKg: 40,
      band: FreshnessBand.good,
      status: OrderStatus.completed,
      placedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
  ];

  @override
  Future<List<Offer>> fetchOffers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_offers);
  }

  @override
  Future<List<Order>> fetchOrders() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_orders);
  }

  @override
  Future<Order> placeOrder({
    required Offer offer,
    required double quantityKg,
  }) async {
    await Future.delayed(const Duration(milliseconds: 450));
    final order = Order(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      vendorName: offer.vendorName,
      vegetable: offer.vegetable,
      quantityKg: quantityKg,
      pricePerKg: offer.offerPrice,
      marketPricePerKg: offer.marketPrice,
      band: offer.band,
      status: OrderStatus.confirmed,
      placedAt: DateTime.now(),
      imagePath: offer.imagePath,
    );
    _orders.insert(0, order);
    return order;
  }
}
