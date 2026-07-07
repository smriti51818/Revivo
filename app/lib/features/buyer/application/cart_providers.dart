import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cart_item.dart';
import '../domain/offer.dart';

/// The buyer's cart. Lines are keyed by offer id; adding an existing offer
/// tops up its quantity (clamped to what the vendor has left).
class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  void add(Offer offer, double quantityKg) {
    final idx = state.indexWhere((c) => c.offer.id == offer.id);
    if (idx >= 0) {
      final merged = (state[idx].quantityKg + quantityKg)
          .clamp(0.1, offer.availableKg)
          .toDouble();
      _replaceAt(idx, state[idx].copyWith(quantityKg: merged));
    } else {
      final qty = quantityKg.clamp(0.1, offer.availableKg).toDouble();
      state = [...state, CartItem(offer: offer, quantityKg: qty)];
    }
  }

  void setQuantity(String offerId, double quantityKg) {
    final idx = state.indexWhere((c) => c.offer.id == offerId);
    if (idx < 0) return;
    if (quantityKg <= 0) {
      remove(offerId);
      return;
    }
    final clamped =
        quantityKg.clamp(0.1, state[idx].offer.availableKg).toDouble();
    _replaceAt(idx, state[idx].copyWith(quantityKg: clamped));
  }

  void remove(String offerId) =>
      state = state.where((c) => c.offer.id != offerId).toList();

  void clear() => state = const [];

  void _replaceAt(int idx, CartItem item) {
    final next = [...state];
    next[idx] = item;
    state = next;
  }
}

final cartProvider =
    NotifierProvider<CartController, List<CartItem>>(CartController.new);

/// Distinct-line count, for the cart badge.
final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).length);

final cartBillProvider =
    Provider<CartBill>((ref) => CartBill.of(ref.watch(cartProvider)));
