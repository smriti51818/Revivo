import '../../../core/models/freshness.dart';

/// A surplus offer visible to buyers in the marketplace. It surfaces a vendor's
/// listing with an explicit market-vs-offer price so the saving is honest and
/// obvious — the core value proposition of the Sell track.
class Offer {
  const Offer({
    required this.id,
    required this.vendorName,
    required this.vegetable,
    required this.availableKg,
    required this.marketPrice,
    required this.offerPrice,
    required this.band,
    required this.timeRange,
    required this.distanceKm,
    this.organic = false,
    this.imagePath,
  });

  final String id;
  final String vendorName;
  final String vegetable;
  final double availableKg;

  /// Reference market price per kg (what the buyer would normally pay).
  final double marketPrice;

  /// Freshness-adjusted price per kg offered on Revivo.
  final double offerPrice;

  final FreshnessBand band;
  final String timeRange;
  final double distanceKm;
  final bool organic;
  final String? imagePath;

  double get savingsPerKg =>
      (marketPrice - offerPrice).clamp(0, marketPrice).toDouble();

  int get savingsPct =>
      marketPrice <= 0 ? 0 : ((savingsPerKg / marketPrice) * 100).round();
}
