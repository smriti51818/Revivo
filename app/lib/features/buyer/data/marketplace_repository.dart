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

/// One row of demo produce, with a live shelf window so the countdown ticks
/// even in the offline (in-memory) build.
typedef _Spec = ({
  String id,
  String vendor,
  String veg,
  double kg,
  double market,
  double remainingH,
  double totalH,
  double distance,
  bool organic,
});

class InMemoryMarketplaceRepository implements MarketplaceRepository {
  static const List<_Spec> _specs = [
    (id: 'off_tomato', vendor: 'GreenLeaf Farms', veg: 'Roma Tomatoes', kg: 12, market: 40, remainingH: 16, totalH: 30, distance: 1.2, organic: true),
    (id: 'off_pepper', vendor: 'Anna Vegetable Stall', veg: 'Bell Pepper Mix', kg: 6, market: 60, remainingH: 9, totalH: 30, distance: 2.1, organic: false),
    (id: 'off_spinach', vendor: 'Kovai Fresh Mart', veg: 'Baby Spinach', kg: 4, market: 30, remainingH: 2.5, totalH: 24, distance: 0.8, organic: false),
    (id: 'off_carrot', vendor: 'Sunrise Organics', veg: 'Garden Carrots', kg: 20, market: 45, remainingH: 108, totalH: 200, distance: 3.4, organic: true),
    (id: 'off_cauliflower', vendor: 'RS Traders', veg: 'Cauliflower', kg: 9, market: 35, remainingH: 11, totalH: 36, distance: 1.7, organic: false),
    (id: 'off_beans', vendor: 'Daily Greens', veg: 'French Beans', kg: 5, market: 50, remainingH: 3.5, totalH: 30, distance: 2.9, organic: false),
  ];

  List<Offer> _buildOffers() {
    final now = DateTime.now();
    return [
      for (final s in _specs)
        () {
          final expiresAt =
              now.add(Duration(minutes: (s.remainingH * 60).round()));
          final band = FreshnessBand.fromRatio(s.remainingH / s.totalH);
          final offerPrice = double.parse(
              (s.market * band.priceFactor).toStringAsFixed(2));
          return Offer(
            id: s.id,
            vendorName: s.vendor,
            vegetable: s.veg,
            availableKg: s.kg,
            marketPrice: s.market,
            offerPrice: offerPrice,
            band: band,
            timeRange: s.remainingH >= 48
                ? '~${(s.remainingH / 24).round()} days'
                : '~${s.remainingH.round()} h',
            distanceKm: s.distance,
            organic: s.organic,
            expiresAt: expiresAt,
            totalHours: s.totalH,
          );
        }(),
    ];
  }

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
    return List.unmodifiable(_buildOffers());
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
      pricePerKg: offer.livePrice(),
      marketPricePerKg: offer.marketPrice,
      band: offer.liveBand(),
      status: OrderStatus.confirmed,
      placedAt: DateTime.now(),
      imagePath: offer.imagePath,
    );
    _orders.insert(0, order);
    return order;
  }
}
