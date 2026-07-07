import '../../../core/models/freshness.dart';
import '../domain/rescue.dart';

/// Data source for rescues. The Cook/NGO inbox reads and mutates this list,
/// mirroring how a single DynamoDB item transitions through the rescue
/// lifecycle (accept → pickup → delivered). Swapped for HTTP after deploy.
abstract class RescueRepository {
  Future<List<Rescue>> fetchRescues();
  Future<Rescue> updateStatus(String id,
      {required RescueStatus status, String? ngoName});

  /// Offer a lot to the rescue network (POST /rescues) — used by the seller to
  /// route surplus out of the market before it expires. Starts OFFERED.
  Future<Rescue> createRescue({
    required String vendorName,
    required String pickupArea,
    required String vegetable,
    required double quantityKg,
    required FreshnessBand band,
    required String timeRange,
    double distanceKm,
  });

  /// A short AI-generated "why rescue this?" explanation (Bedrock/Nova).
  Future<String> explain(String id);
}

class InMemoryRescueRepository implements RescueRepository {
  final List<Rescue> _items = [
    const Rescue(
      id: 'rsc_spinach',
      vendorName: 'Kovai Fresh Mart',
      pickupArea: 'RS Puram',
      vegetable: 'Baby Spinach',
      quantityKg: 4,
      band: FreshnessBand.rescue,
      timeRange: '~2-3 h',
      distanceKm: 0.8,
      status: RescueStatus.offered,
    ),
    const Rescue(
      id: 'rsc_beans',
      vendorName: 'Daily Greens',
      pickupArea: 'Gandhipuram',
      vegetable: 'French Beans',
      quantityKg: 5,
      band: FreshnessBand.rescue,
      timeRange: '~3-4 h',
      distanceKm: 2.9,
      status: RescueStatus.offered,
    ),
    const Rescue(
      id: 'rsc_tomato',
      vendorName: 'Anna Vegetable Stall',
      pickupArea: 'Town Hall',
      vegetable: 'Tomatoes',
      quantityKg: 8,
      band: FreshnessBand.rescue,
      timeRange: '~4-5 h',
      distanceKm: 2.1,
      status: RescueStatus.accepted,
      ngoName: 'Annapoorna Trust',
    ),
    const Rescue(
      id: 'rsc_cauli',
      vendorName: 'RS Traders',
      pickupArea: 'Peelamedu',
      vegetable: 'Cauliflower',
      quantityKg: 6,
      band: FreshnessBand.rescue,
      timeRange: '~3-4 h',
      distanceKm: 1.7,
      status: RescueStatus.pickedUp,
      ngoName: 'Seva Kitchen',
    ),
    const Rescue(
      id: 'rsc_carrot',
      vendorName: 'GreenLeaf Farms',
      pickupArea: 'Saibaba Colony',
      vegetable: 'Garden Carrots',
      quantityKg: 10,
      band: FreshnessBand.rescue,
      timeRange: 'delivered',
      distanceKm: 3.4,
      status: RescueStatus.delivered,
      ngoName: 'Annapoorna Trust',
    ),
  ];

  @override
  Future<List<Rescue>> fetchRescues() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }

  @override
  Future<Rescue> updateStatus(String id,
      {required RescueStatus status, String? ngoName}) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final idx = _items.indexWhere((r) => r.id == id);
    if (idx == -1) {
      throw StateError('Rescue $id not found');
    }
    final updated = _items[idx].copyWith(status: status, ngoName: ngoName);
    _items[idx] = updated;
    return updated;
  }

  @override
  Future<Rescue> createRescue({
    required String vendorName,
    required String pickupArea,
    required String vegetable,
    required double quantityKg,
    required FreshnessBand band,
    required String timeRange,
    double distanceKm = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final rescue = Rescue(
      id: 'rsc_${DateTime.now().microsecondsSinceEpoch}',
      vendorName: vendorName,
      pickupArea: pickupArea,
      vegetable: vegetable,
      quantityKg: quantityKg,
      band: band,
      timeRange: timeRange,
      distanceKm: distanceKm,
      status: RescueStatus.offered,
    );
    _items.insert(0, rescue);
    return rescue;
  }

  @override
  Future<String> explain(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final r = _items.firstWhere((r) => r.id == id);
    return '${r.quantityKg.toStringAsFixed(0)} kg of ${r.vegetable} can become '
        'roughly ${r.estimatedMeals} meals. It\'s in its final freshness '
        'window, so rescuing it today keeps good food out of landfill.';
  }
}
