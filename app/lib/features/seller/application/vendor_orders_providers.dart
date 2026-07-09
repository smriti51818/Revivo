import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../../buyer/domain/order.dart';
import '../data/http_vendor_orders_repository.dart';
import '../data/vendor_orders_repository.dart';

final vendorOrdersRepositoryProvider =
    Provider<VendorOrdersRepository>((ref) {
  final config = ref.read(appConfigProvider);
  if (!config.useLiveApi) return InMemoryVendorOrdersRepository();
  return HttpVendorOrdersRepository(ref.read(apiClientProvider));
});

/// Live incoming orders for this seller. Polled so the Step Functions
/// lifecycle (Confirmed → Preparing → Ready → Completed) shows up live.
class VendorOrdersController extends AsyncNotifier<List<Order>> {
  /// Orders the seller declined. Kept client-side (the pilot has no reject
  /// endpoint) and filtered out of every fetch so a rejected order stays gone
  /// across the 8s poll instead of reappearing.
  final Set<String> _rejected = {};

  List<Order> _visible(List<Order> orders) =>
      orders.where((o) => !_rejected.contains(o.id)).toList();

  @override
  Future<List<Order>> build() async {
    final orders =
        await ref.read(vendorOrdersRepositoryProvider).fetchIncoming();
    return _visible(orders);
  }

  Future<void> reload() async {
    try {
      final orders =
          await ref.read(vendorOrdersRepositoryProvider).fetchIncoming();
      state = AsyncData(_visible(orders));
    } catch (_) {
      // Keep current data on a transient poll failure.
    }
  }

  /// Seller declines an incoming order — it's removed from the queue and stays
  /// out across polls.
  void reject(String orderId) {
    _rejected.add(orderId);
    final current = state.valueOrNull ?? const <Order>[];
    state = AsyncData([
      for (final o in current)
        if (o.id != orderId) o,
    ]);
  }

  /// Vendor marks an order ready for pickup or handed over.
  Future<void> advance(String orderId, OrderStatus status) async {
    final updated = await ref
        .read(vendorOrdersRepositoryProvider)
        .advance(orderId, status);
    final current = state.valueOrNull ?? const <Order>[];
    state = AsyncData([
      for (final o in current) o.id == orderId ? updated : o,
    ]);
  }
}

final vendorOrdersProvider =
    AsyncNotifierProvider<VendorOrdersController, List<Order>>(
  VendorOrdersController.new,
);
