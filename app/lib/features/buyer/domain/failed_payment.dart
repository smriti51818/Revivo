/// A single line captured from the cart at the moment a payment failed.
class FailedPaymentLine {
  const FailedPaymentLine({
    required this.vegetable,
    required this.vendorName,
    required this.quantityKg,
    required this.pricePerKg,
    this.imageUrl,
  });

  final String vegetable;
  final String vendorName;
  final double quantityKg;
  final double pricePerKg;
  final String? imageUrl;

  double get lineTotal => quantityKg * pricePerKg;
}

/// A checkout attempt that did not complete — the payment was declined or
/// cancelled, so no order was created. Kept client-side so the buyer can see it
/// under "Payment failed" and retry. (There is no payment gateway in the pilot;
/// this models the failure path for the demo.)
class FailedPayment {
  const FailedPayment({
    required this.id,
    required this.lines,
    required this.amount,
    required this.method,
    required this.pickupSlot,
    required this.attemptedAt,
    required this.reason,
  });

  final String id;
  final List<FailedPaymentLine> lines;
  final double amount;
  final String method;
  final String pickupSlot;
  final DateTime attemptedAt;
  final String reason;

  int get itemCount => lines.length;
}
