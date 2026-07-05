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
    this.imageUrl,
    this.purchasedAt,
    this.tempC,
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

  /// Local file path of a just-picked photo (seller device), pre-upload.
  final String? imagePath;

  /// Remote (presigned) URL of the stored photo, for display.
  final String? imageUrl;

  /// When the produce was purchased/harvested — sent to the server so it can
  /// compute the authoritative freshness band. Null for seeded demo data.
  final DateTime? purchasedAt;
  final double? tempC;

  bool get isLowStock => quantityKg <= 3;
}
