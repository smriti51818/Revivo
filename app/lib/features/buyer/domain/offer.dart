import '../../../core/freshness/live_clock.dart';
import '../../../core/models/freshness.dart';

/// A surplus offer visible to buyers in the marketplace. It surfaces a vendor's
/// listing with an explicit market-vs-offer price so the saving is honest and
/// obvious — the core value proposition of the Sell track.
///
/// When [expiresAt] + [totalHours] are present, the band and price are treated
/// as *live*: they decay continuously as the countdown ticks, so [liveBand] and
/// [livePrice] — not the fetch-time snapshot — should drive the UI.
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
    this.imageUrl,
    this.expiresAt,
    this.totalHours,
  });

  final String id;
  final String vendorName;
  final String vegetable;
  final double availableKg;

  /// Reference market price per kg (what the buyer would normally pay).
  final double marketPrice;

  /// Freshness-adjusted price per kg offered on Revivo (fetch-time snapshot).
  final double offerPrice;

  final FreshnessBand band;
  final String timeRange;
  final double distanceKm;
  final bool organic;
  final String? imagePath;

  /// Remote (presigned) URL of the produce photo, for display.
  final String? imageUrl;

  /// Absolute moment this produce leaves its usable window, and the full shelf
  /// window it started with — the two inputs that drive the live countdown.
  final DateTime? expiresAt;
  final double? totalHours;

  bool get hasClock =>
      expiresAt != null && totalHours != null && totalHours! > 0;

  bool isExpired([DateTime? now]) =>
      hasClock && !expiresAt!.isAfter(now ?? DateTime.now());

  /// The freshness band recomputed for [now] (falls back to the snapshot).
  FreshnessBand liveBand([DateTime? now]) => hasClock
      ? LiveClock.band(
          expiresAt: expiresAt!, totalHours: totalHours!, now: now)
      : band;

  /// The live, freshness-decayed price per kg (falls back to the snapshot).
  double livePrice([DateTime? now]) => hasClock
      ? LiveClock.price(
          marketPrice: marketPrice,
          expiresAt: expiresAt!,
          totalHours: totalHours!,
          now: now,
        )
      : offerPrice;

  double liveSavingsPerKg([DateTime? now]) =>
      (marketPrice - livePrice(now)).clamp(0, marketPrice).toDouble();

  int liveSavingsPct([DateTime? now]) => marketPrice <= 0
      ? 0
      : ((liveSavingsPerKg(now) / marketPrice) * 100).round();

  double get savingsPerKg =>
      (marketPrice - offerPrice).clamp(0, marketPrice).toDouble();

  int get savingsPct =>
      marketPrice <= 0 ? 0 : ((savingsPerKg / marketPrice) * 100).round();
}
