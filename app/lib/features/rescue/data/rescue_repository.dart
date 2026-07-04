import '../../../core/models/freshness.dart';
import '../domain/rescue.dart';

/// Shared data source for rescues. Both the Cook/NGO inbox and the Volunteer
/// pickup board read and mutate this list, mirroring how a single DynamoDB
/// item transitions through the rescue lifecycle. Swapped for HTTP after deploy.
abstract class RescueRepository {
  Future<List<Rescue>> fetchRescues();
  Future<Rescue> updateStatus(String id,
      {required RescueStatus status, String? ngoName});
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
}
