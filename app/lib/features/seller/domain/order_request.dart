import '../../../core/models/freshness.dart';

/// State of an incoming buyer request from the seller's point of view.
enum RequestStatus {
  pending('Pending'),
  accepted('Accepted'),
  declined('Declined'),
  completed('Completed');

  const RequestStatus(this.label);
  final String label;
}

/// A buyer's request to purchase surplus from this seller.
class OrderRequest {
  const OrderRequest({
    required this.id,
    required this.buyerName,
    required this.buyerType,
    required this.vegetable,
    required this.quantityKg,
    required this.pricePerKg,
    required this.band,
    required this.status,
    required this.placedAt,
  });

  final String id;
  final String buyerName;
  final String buyerType;
  final String vegetable;
  final double quantityKg;
  final double pricePerKg;
  final FreshnessBand band;
  final RequestStatus status;
  final DateTime placedAt;

  double get total => quantityKg * pricePerKg;

  OrderRequest copyWith({RequestStatus? status}) => OrderRequest(
        id: id,
        buyerName: buyerName,
        buyerType: buyerType,
        vegetable: vegetable,
        quantityKg: quantityKg,
        pricePerKg: pricePerKg,
        band: band,
        status: status ?? this.status,
        placedAt: placedAt,
      );
}
