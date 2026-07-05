import '../../../core/models/freshness.dart';

/// Lifecycle of a surplus rescue as it moves from vendor → NGO kitchen.
/// In M7 this is orchestrated by a Step Functions state machine; the mock
/// advances it locally so the full loop is demoable offline.
enum RescueStatus {
  offered('New'),
  accepted('Accepted'),
  assigned('Pickup assigned'),
  pickedUp('In transit'),
  delivered('Delivered');

  const RescueStatus(this.label);
  final String label;

  static RescueStatus fromValue(String? value) => switch (value?.toUpperCase()) {
        'ACCEPTED' => RescueStatus.accepted,
        'ASSIGNED' => RescueStatus.assigned,
        'PICKED_UP' || 'PICKEDUP' => RescueStatus.pickedUp,
        'DELIVERED' => RescueStatus.delivered,
        _ => RescueStatus.offered,
      };
}

/// Surplus produce routed to an NGO kitchen when it enters the rescue window.
/// The pickup leg is handled by a volunteer.
class Rescue {
  const Rescue({
    required this.id,
    required this.vendorName,
    required this.pickupArea,
    required this.vegetable,
    required this.quantityKg,
    required this.band,
    required this.timeRange,
    required this.distanceKm,
    required this.status,
    this.ngoName,
  });

  final String id;
  final String vendorName;
  final String pickupArea;
  final String vegetable;
  final double quantityKg;
  final FreshnessBand band;
  final String timeRange;
  final double distanceKm;
  final RescueStatus status;
  final String? ngoName;

  /// Rough meal yield — ~0.4 kg of produce per served meal.
  int get estimatedMeals => (quantityKg / 0.4).round();

  Rescue copyWith({RescueStatus? status, String? ngoName}) => Rescue(
        id: id,
        vendorName: vendorName,
        pickupArea: pickupArea,
        vegetable: vegetable,
        quantityKg: quantityKg,
        band: band,
        timeRange: timeRange,
        distanceKm: distanceKm,
        status: status ?? this.status,
        ngoName: ngoName ?? this.ngoName,
      );
}
