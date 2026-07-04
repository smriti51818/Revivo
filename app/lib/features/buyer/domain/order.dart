import '../../../core/models/freshness.dart';

/// Lifecycle of a buyer order. In M7 this is driven by a Step Functions state
/// machine; for now the mock advances it locally.
enum OrderStatus {
  confirmed('Confirmed'),
  preparing('Preparing'),
  readyForPickup('Ready for pickup'),
  completed('Completed');

  const OrderStatus(this.label);
  final String label;
}

/// A buyer's order placed against a surplus [offer].
class Order {
  const Order({
    required this.id,
    required this.vendorName,
    required this.vegetable,
    required this.quantityKg,
    required this.pricePerKg,
    required this.marketPricePerKg,
    required this.band,
    required this.status,
    required this.placedAt,
    this.imagePath,
  });

  final String id;
  final String vendorName;
  final String vegetable;
  final double quantityKg;
  final double pricePerKg;
  final double marketPricePerKg;
  final FreshnessBand band;
  final OrderStatus status;
  final DateTime placedAt;
  final String? imagePath;

  double get total => quantityKg * pricePerKg;

  double get saved =>
      ((marketPricePerKg - pricePerKg).clamp(0, marketPricePerKg) * quantityKg)
          .toDouble();

  Order copyWith({OrderStatus? status}) => Order(
        id: id,
        vendorName: vendorName,
        vegetable: vegetable,
        quantityKg: quantityKg,
        pricePerKg: pricePerKg,
        marketPricePerKg: marketPricePerKg,
        band: band,
        status: status ?? this.status,
        placedAt: placedAt,
        imagePath: imagePath,
      );
}
