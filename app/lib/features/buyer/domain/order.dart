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

  static OrderStatus fromValue(String? value) => switch (value?.toUpperCase()) {
        'PREPARING' => OrderStatus.preparing,
        'READY_FOR_PICKUP' || 'READYFORPICKUP' => OrderStatus.readyForPickup,
        'COMPLETED' => OrderStatus.completed,
        _ => OrderStatus.confirmed,
      };
}

/// Settlement state of an order's payment. A successful order is either already
/// paid (online) or due on pickup; failed attempts never become orders (see
/// `FailedPayment`).
enum PaymentStatus {
  paid('Paid'),
  payOnPickup('Pay on pickup');

  const PaymentStatus(this.label);
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
    this.buyerName,
    this.pickupSlot = '',
    this.paymentMethod = 'PICKUP',
    this.rating,
    this.ratingTags = const [],
    this.ratingComment = '',
  });

  final String id;
  final String vendorName;

  /// Who placed the order — shown on the seller's incoming-orders view.
  final String? buyerName;
  final String vegetable;
  final double quantityKg;
  final double pricePerKg;
  final double marketPricePerKg;
  final FreshnessBand band;
  final OrderStatus status;
  final DateTime placedAt;
  final String? imagePath;

  /// Chosen self-pickup window (e.g. "7:00–7:30 PM") and how it's paid.
  final String pickupSlot;
  final String paymentMethod;

  /// Post-pickup quality feedback (null until the buyer rates it).
  final int? rating;
  final List<String> ratingTags;
  final String ratingComment;

  bool get isRated => rating != null && rating! > 0;

  /// A stable 4-digit pickup handover code derived from the order id — the buyer
  /// shows it and the vendor confirms it at handover. Identical on both sides
  /// with no round-trip, since it's a pure function of the id.
  String get handoverCode {
    var h = 0;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return (h % 9000 + 1000).toString();
  }

  /// Online orders are prepaid; pay-on-pickup settles at the vendor.
  PaymentStatus get paymentStatus => paymentMethod.toUpperCase() == 'PICKUP'
      ? PaymentStatus.payOnPickup
      : PaymentStatus.paid;

  double get total => quantityKg * pricePerKg;

  double get saved =>
      ((marketPricePerKg - pricePerKg).clamp(0, marketPricePerKg) * quantityKg)
          .toDouble();

  Order copyWith({OrderStatus? status}) => Order(
        id: id,
        vendorName: vendorName,
        buyerName: buyerName,
        vegetable: vegetable,
        quantityKg: quantityKg,
        pricePerKg: pricePerKg,
        marketPricePerKg: marketPricePerKg,
        band: band,
        status: status ?? this.status,
        placedAt: placedAt,
        imagePath: imagePath,
        pickupSlot: pickupSlot,
        paymentMethod: paymentMethod,
        rating: rating,
        ratingTags: ratingTags,
        ratingComment: ratingComment,
      );
}
