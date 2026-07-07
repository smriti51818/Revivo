import 'coupon.dart';
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
    required this.couponDiscount,
    required this.total,
    this.couponCode,
  });

  final double itemTotal;

  /// Saving vs the reference market price (before any coupon).
  final double saved;
  final double platformFee;

  /// Discount from an applied Revivo coupon (0 when none / not eligible).
  final double couponDiscount;

  /// The applied coupon's code, if it produced a discount.
  final String? couponCode;

  final double total;

  /// The full amount kept off the market price: market savings + coupon.
  double get totalSaved => saved + couponDiscount;

  factory CartBill.of(List<CartItem> items, {Coupon? coupon}) {
    final itemTotal = items.fold<double>(0, (s, c) => s + c.lineTotal);
    final saved = items.fold<double>(0, (s, c) => s + c.lineSaved);
    final fee = items.isEmpty ? 0.0 : kPlatformFee;
    final discount = coupon == null
        ? 0.0
        : coupon.discountFor(itemTotal: itemTotal, platformFee: fee);
    final total = (itemTotal + fee - discount).clamp(0, double.infinity);
    return CartBill(
      itemTotal: itemTotal,
      saved: saved,
      platformFee: fee,
      couponDiscount: discount,
      couponCode: discount > 0 ? coupon?.code : null,
      total: total.toDouble(),
    );
  }
}
