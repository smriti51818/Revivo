import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/http_marketplace_repository.dart';
import '../data/marketplace_repository.dart';
import '../domain/offer.dart';
import '../domain/order.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  final config = ref.read(appConfigProvider);
  if (!config.useLiveApi) return InMemoryMarketplaceRepository();
  return HttpMarketplaceRepository(ref.read(apiClientProvider));
});

/// Nearby surplus offers surfaced to the buyer.
class OffersController extends AsyncNotifier<List<Offer>> {
  @override
  Future<List<Offer>> build() {
    return ref.read(marketplaceRepositoryProvider).fetchOffers();
  }
}

final offersProvider =
    AsyncNotifierProvider<OffersController, List<Offer>>(OffersController.new);

/// The buyer's orders. Placing an order prepends it so the list updates live.
class OrdersController extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() {
    return ref.read(marketplaceRepositoryProvider).fetchOrders();
  }

  Future<Order> placeOrder({
    required Offer offer,
    required double quantityKg,
  }) async {
    final order = await ref
        .read(marketplaceRepositoryProvider)
        .placeOrder(offer: offer, quantityKg: quantityKg);
    final current = state.valueOrNull ?? const <Order>[];
    state = AsyncData([order, ...current]);
    return order;
  }

  /// Silently re-fetches (no loading flicker) — used to poll while the Step
  /// Functions lifecycle advances an order's status server-side.
  Future<void> reload() async {
    try {
      final orders =
          await ref.read(marketplaceRepositoryProvider).fetchOrders();
      state = AsyncData(orders);
    } catch (_) {
      // Keep the current data on a transient poll failure.
    }
  }
}

final ordersProvider =
    AsyncNotifierProvider<OrdersController, List<Order>>(OrdersController.new);
