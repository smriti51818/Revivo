import '../../../core/models/freshness.dart';

enum StorageCondition {
  room('ROOM', 'Room temperature'),
  refrigerated('REFRIGERATED', 'Refrigerated'),
  coldStorage('COLD_STORAGE', 'Cold storage');

  const StorageCondition(this.value, this.label);
  final String value;
  final String label;
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
  final String? imagePath;

  bool get isLowStock => quantityKg <= 3;
}
