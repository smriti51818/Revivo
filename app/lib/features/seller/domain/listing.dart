import '../../../core/freshness/live_clock.dart';
import '../../../core/models/freshness.dart';

enum StorageCondition {
  room('ROOM', 'Room temperature'),
  refrigerated('REFRIGERATED', 'Refrigerated'),
  coldStorage('COLD_STORAGE', 'Cold storage');

  const StorageCondition(this.value, this.label);
  final String value;
  final String label;

  static StorageCondition fromValue(String? value) => switch (value?.toUpperCase()) {
        'REFRIGERATED' => StorageCondition.refrigerated,
        'COLD_STORAGE' => StorageCondition.coldStorage,
        _ => StorageCondition.room,
      };
}

/// A surplus listing shown on the seller dashboard.
class Listing {
  const Listing({
    required this.id,
    required this.vegetable,
    required this.quantityKg,
    required this.basePrice,
    required this.recommendedPrice,
    required this.band,
    required this.timeRange,
    required this.storage,
    required this.createdAt,
    this.organic = false,
    this.imagePath,
    this.imageKey,
    this.imageUrl,
    this.purchasedAt,
    this.tempC,
    this.expiresAt,
    this.totalHours,
  });

  final String id;
  final String vegetable;
  final double quantityKg;
  final double basePrice;
  final double recommendedPrice;
  final FreshnessBand band;
  final String timeRange;
  final StorageCondition storage;
  final DateTime createdAt;
  final bool organic;

  /// Local file path of a just-captured photo (seller device), for display.
  final String? imagePath;

  /// S3 object key of the uploaded photo (set at capture time so Rekognition
  /// can read it); reused at publish so the photo isn't uploaded twice.
  final String? imageKey;

  /// Remote (presigned) URL of the stored photo, for display.
  final String? imageUrl;

  /// When the produce was purchased/harvested — sent to the server so it can
  /// compute the authoritative freshness band. Null for seeded demo data.
  final DateTime? purchasedAt;
  final double? tempC;

  /// Absolute expiry + full shelf window — drive the live countdown on the
  /// seller's own inventory, mirroring what buyers see in the market.
  final DateTime? expiresAt;
  final double? totalHours;

  bool get isLowStock => quantityKg <= 3;

  bool get hasClock =>
      expiresAt != null && totalHours != null && totalHours! > 0;

  /// The freshness band recomputed for [now] as the clock ticks (falls back to
  /// the fetch-time snapshot when this listing has no live-clock inputs).
  FreshnessBand liveBand([DateTime? now]) => hasClock
      ? LiveClock.band(expiresAt: expiresAt!, totalHours: totalHours!, now: now)
      : band;

  /// The live, freshness-decayed price per kg — market price scaled by the
  /// current band's factor (falls back to the stored recommended price).
  double livePricePerKg([DateTime? now]) => hasClock
      ? LiveClock.price(
          marketPrice: basePrice,
          expiresAt: expiresAt!,
          totalHours: totalHours!,
          now: now,
        )
      : recommendedPrice;

  /// What the remaining stock is worth right now at the live price.
  double liveValue([DateTime? now]) => quantityKg * livePricePerKg(now);

  /// What the same stock would fetch at full market price (no decay).
  double get freshValue => quantityKg * basePrice;

  /// True once the lot has decayed into the Use-soon or Rescue band — its price
  /// is actively falling and it needs the seller's attention.
  bool atRisk([DateTime? now]) {
    final b = liveBand(now);
    return b == FreshnessBand.useSoon || b == FreshnessBand.rescue;
  }

  /// When this lot next crosses into a lower band (and its price steps down),
  /// or null once it's already in the Rescue band. Mirrors the backend
  /// thresholds: GOOD below 0.5 of shelf life, USE_SOON below 0.2.
  DateTime? nextDropAt([DateTime? now]) {
    if (!hasClock) return null;
    final total = totalHours!;
    final ratio =
        LiveClock.ratio(expiresAt: expiresAt!, totalHours: total, now: now);
    if (ratio > 0.5) {
      return expiresAt!.subtract(Duration(seconds: (0.5 * total * 3600).round()));
    }
    if (ratio > 0.2) {
      return expiresAt!.subtract(Duration(seconds: (0.2 * total * 3600).round()));
    }
    return null;
  }

  Listing copyWith({double? quantityKg}) => Listing(
        id: id,
        vegetable: vegetable,
        quantityKg: quantityKg ?? this.quantityKg,
        basePrice: basePrice,
        recommendedPrice: recommendedPrice,
        band: band,
        timeRange: timeRange,
        storage: storage,
        createdAt: createdAt,
        organic: organic,
        imagePath: imagePath,
        imageKey: imageKey,
        imageUrl: imageUrl,
        purchasedAt: purchasedAt,
        tempC: tempC,
        expiresAt: expiresAt,
        totalHours: totalHours,
      );
}
