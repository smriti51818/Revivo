import '../models/freshness.dart';

/// Live decay math shared by the countdown widget and the marketplace models.
///
/// Everything derives from two immutable facts the server sends per listing:
/// the absolute [expiresAt] and the full shelf window [totalHours]. From those
/// we recompute the freshness band and price factor for *now*, so the band and
/// price visibly decay between server fetches — the heart of Revivo's clock.
class LiveClock {
  const LiveClock._();

  /// Remaining/total life ratio at [now] (clamped at 0; can exceed 1 briefly).
  static double ratio({
    required DateTime expiresAt,
    required double totalHours,
    DateTime? now,
  }) {
    if (totalHours <= 0) return 1;
    final remaining =
        expiresAt.difference(now ?? DateTime.now()).inSeconds / 3600.0;
    final r = remaining / totalHours;
    return r < 0 ? 0 : r;
  }

  static FreshnessBand band({
    required DateTime expiresAt,
    required double totalHours,
    DateTime? now,
  }) =>
      FreshnessBand.fromRatio(
        ratio(expiresAt: expiresAt, totalHours: totalHours, now: now),
      );

  /// The live per-kg price: market price scaled by the current band's factor,
  /// rounded to paise so it matches what the backend charges on order.
  static double price({
    required double marketPrice,
    required DateTime expiresAt,
    required double totalHours,
    DateTime? now,
  }) {
    final factor =
        band(expiresAt: expiresAt, totalHours: totalHours, now: now).priceFactor;
    return double.parse((marketPrice * factor).toStringAsFixed(2));
  }
}
