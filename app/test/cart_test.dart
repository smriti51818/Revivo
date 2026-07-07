import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revivo/core/models/freshness.dart';
import 'package:revivo/features/buyer/application/cart_providers.dart';
import 'package:revivo/features/buyer/domain/cart_item.dart';
import 'package:revivo/features/buyer/domain/offer.dart';

Offer _offer(String id, {double price = 30, double available = 10}) => Offer(
      id: id,
      vendorName: 'V',
      vegetable: 'Tomato',
      availableKg: available,
      marketPrice: 40,
      offerPrice: price, // no clock -> livePrice falls back to this
      band: FreshnessBand.useSoon,
      timeRange: '',
      distanceKm: 0,
    );

void main() {
  group('CartController', () {
    test('adds, merges duplicate lines, and clamps to stock', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier);

      cart.add(_offer('a'), 2);
      cart.add(_offer('a', available: 10), 3); // same line -> 5kg
      cart.add(_offer('b'), 1);

      final items = c.read(cartProvider);
      expect(items.length, 2);
      expect(items.firstWhere((i) => i.offer.id == 'a').quantityKg, 5);
      expect(c.read(cartCountProvider), 2);
    });

    test('setQuantity to zero removes the line; clear empties the cart', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier);

      cart.add(_offer('a'), 2);
      cart.setQuantity('a', 0);
      expect(c.read(cartProvider), isEmpty);

      cart.add(_offer('a'), 1);
      cart.clear();
      expect(c.read(cartProvider), isEmpty);
    });
  });

  group('CartBill', () {
    test('sums item totals, savings, and adds the platform fee', () {
      final items = [
        CartItem(offer: _offer('a', price: 30), quantityKg: 2), // 60
        CartItem(offer: _offer('b', price: 20), quantityKg: 1), // 20
      ];
      final bill = CartBill.of(items);
      expect(bill.itemTotal, 80);
      expect(bill.platformFee, kPlatformFee);
      expect(bill.total, 80 + kPlatformFee);
      // market 40 vs 30 -> save 10*2=20; 40 vs 20 -> 20*1=20; total 40.
      expect(bill.saved, 40);
    });

    test('is free of platform fee when empty', () {
      final bill = CartBill.of(const []);
      expect(bill.total, 0);
      expect(bill.platformFee, 0);
    });
  });
}
