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
  @override
  Future<List<Order>> build() {
    return ref.read(vendorOrdersRepositoryProvider).fetchIncoming();
  }

  Future<void> reload() async {
    try {
      final orders =
          await ref.read(vendorOrdersRepositoryProvider).fetchIncoming();
      state = AsyncData(orders);
    } catch (_) {
      // Keep current data on a transient poll failure.
    }
  }
}

final vendorOrdersProvider =
    AsyncNotifierProvider<VendorOrdersController, List<Order>>(
  VendorOrdersController.new,
);
