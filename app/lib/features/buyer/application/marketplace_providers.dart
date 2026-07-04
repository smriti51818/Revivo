import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/marketplace_repository.dart';
import '../domain/offer.dart';
import '../domain/order.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => InMemoryMarketplaceRepository(),
);

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
}

final ordersProvider =
    AsyncNotifierProvider<OrdersController, List<Order>>(OrdersController.new);
