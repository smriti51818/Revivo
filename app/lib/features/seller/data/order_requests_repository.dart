import '../../../core/models/freshness.dart';
import '../domain/order_request.dart';

abstract class OrderRequestsRepository {
  Future<List<OrderRequest>> fetchRequests();
  Future<OrderRequest> setStatus(String id, RequestStatus status);
}

class InMemoryOrderRequestsRepository implements OrderRequestsRepository {
  final List<OrderRequest> _items = [
    OrderRequest(
      id: 'req_palace',
      buyerName: 'Grand Palace Hotel',
      buyerType: 'Hotel',
      vegetable: 'Heirloom Tomatoes',
      quantityKg: 10,
      pricePerKg: 30,
      band: FreshnessBand.good,
      status: RequestStatus.pending,
      placedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    OrderRequest(
      id: 'req_sunrise',
      buyerName: 'Sunrise Caterers',
      buyerType: 'Caterer',
      vegetable: 'Bell Pepper Mix',
      quantityKg: 2,
      pricePerKg: 31.5,
      band: FreshnessBand.useSoon,
      status: RequestStatus.pending,
      placedAt: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
    OrderRequest(
      id: 'req_annapoorna',
      buyerName: 'Annapoorna Trust',
      buyerType: 'NGO kitchen',
      vegetable: 'Baby Spinach',
      quantityKg: 3,
      pricePerKg: 8,
      band: FreshnessBand.rescue,
      status: RequestStatus.accepted,
      placedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
    ),
    OrderRequest(
      id: 'req_greenbowl',
      buyerName: 'Green Bowl Cafe',
      buyerType: 'Restaurant',
      vegetable: 'Garden Carrots',
      quantityKg: 8,
      pricePerKg: 35,
      band: FreshnessBand.good,
      status: RequestStatus.completed,
      placedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<OrderRequest>> fetchRequests() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }

  @override
  Future<OrderRequest> setStatus(String id, RequestStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _items.indexWhere((r) => r.id == id);
    if (idx == -1) throw StateError('Request $id not found');
    final updated = _items[idx].copyWith(status: status);
    _items[idx] = updated;
    return updated;
  }
}
