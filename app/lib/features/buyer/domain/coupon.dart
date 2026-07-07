/// How a Revivo coupon reduces the bill.
enum CouponType {
  /// A percentage off the item total (optionally capped by [Coupon.maxDiscount]).
  percent,

  /// A flat rupee amount off the item total.
  flat,

  /// Waives the platform fee entirely.
  feeWaiver,
}

/// A promotional coupon offered by Revivo. Client-side for the pilot — there is
/// no coupons endpoint yet, so the catalogue lives in [kRevivoCoupons].
class Coupon {
  const Coupon({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    this.minOrder = 0,
    this.maxDiscount,
  });

  final String code;
  final String title;
  final String description;
  final CouponType type;

  /// Percent (0–100) for [CouponType.percent], rupees for [CouponType.flat].
  /// Unused for [CouponType.feeWaiver].
  final double value;

  /// Minimum item total (₹) required for the coupon to apply.
  final double minOrder;

  /// Optional cap on the discount for [CouponType.percent].
  final double? maxDiscount;

  bool eligible(double itemTotal) => itemTotal >= minOrder;

  /// The rupee discount this coupon yields for a given bill. Returns 0 when the
  /// item total is below [minOrder].
  double discountFor({required double itemTotal, required double platformFee}) {
    if (!eligible(itemTotal)) return 0;
    switch (type) {
      case CouponType.percent:
        final raw = itemTotal * value / 100;
        final capped = maxDiscount == null
            ? raw
            : (raw > maxDiscount! ? maxDiscount! : raw);
        return double.parse(capped.toStringAsFixed(2));
      case CouponType.flat:
        return value > itemTotal ? itemTotal : value;
      case CouponType.feeWaiver:
        return platformFee;
    }
  }
}

/// The coupons Revivo runs during the Coimbatore pilot.
const List<Coupon> kRevivoCoupons = [
  Coupon(
    code: 'RESCUE15',
    title: '15% off your rescue',
    description: 'Save 15% on orders over ₹100 · up to ₹60',
    type: CouponType.percent,
    value: 15,
    minOrder: 100,
    maxDiscount: 60,
  ),
  Coupon(
    code: 'NOFEE',
    title: 'Zero platform fee',
    description: 'We waive the ₹8 platform fee on this order',
    type: CouponType.feeWaiver,
    value: 0,
  ),
  Coupon(
    code: 'FIRST50',
    title: '₹50 off first rescue',
    description: 'Flat ₹50 off orders over ₹200',
    type: CouponType.flat,
    value: 50,
    minOrder: 200,
  ),
];
