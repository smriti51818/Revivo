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
