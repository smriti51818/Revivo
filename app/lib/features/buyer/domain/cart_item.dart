import 'offer.dart';

/// A line in the buyer's cart: an [Offer] plus the quantity they want. Line
/// totals read the offer's *live* price, so the bill tracks the countdown.
class CartItem {
  const CartItem({required this.offer, required this.quantityKg});

  final Offer offer;
  final double quantityKg;

  double get unitPrice => offer.livePrice();
  double get lineTotal => quantityKg * unitPrice;
  double get lineSaved => quantityKg * offer.liveSavingsPerKg();

  CartItem copyWith({double? quantityKg}) =>
      CartItem(offer: offer, quantityKg: quantityKg ?? this.quantityKg);
}

/// Flat platform fee per order, per the pilot business model (₹5–10).
const double kPlatformFee = 8;

/// The itemised bill for a set of cart lines.
class CartBill {
  const CartBill({
    required this.itemTotal,
    required this.saved,
    required this.platformFee,
    required this.total,
  });

  final double itemTotal;
  final double saved;
  final double platformFee;
  final double total;

  factory CartBill.of(List<CartItem> items) {
    final itemTotal = items.fold<double>(0, (s, c) => s + c.lineTotal);
    final saved = items.fold<double>(0, (s, c) => s + c.lineSaved);
    final fee = items.isEmpty ? 0.0 : kPlatformFee;
    return CartBill(
      itemTotal: itemTotal,
      saved: saved,
      platformFee: fee,
      total: itemTotal + fee,
    );
  }
}
