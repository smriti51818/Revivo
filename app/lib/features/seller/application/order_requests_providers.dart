import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_requests_repository.dart';
import '../domain/order_request.dart';

final orderRequestsRepositoryProvider = Provider<OrderRequestsRepository>(
  (ref) => InMemoryOrderRequestsRepository(),
);

/// Incoming buyer requests for this seller's surplus.
class OrderRequestsController extends AsyncNotifier<List<OrderRequest>> {
  @override
  Future<List<OrderRequest>> build() {
    return ref.read(orderRequestsRepositoryProvider).fetchRequests();
  }

  Future<void> _set(String id, RequestStatus status) async {
    final updated =
        await ref.read(orderRequestsRepositoryProvider).setStatus(id, status);
    final current = state.valueOrNull ?? const <OrderRequest>[];
    state = AsyncData([
      for (final r in current) r.id == id ? updated : r,
    ]);
  }

  Future<void> accept(String id) => _set(id, RequestStatus.accepted);
  Future<void> decline(String id) => _set(id, RequestStatus.declined);
}

final orderRequestsProvider =
    AsyncNotifierProvider<OrderRequestsController, List<OrderRequest>>(
  OrderRequestsController.new,
);
