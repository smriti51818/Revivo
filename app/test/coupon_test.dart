import 'package:flutter_test/flutter_test.dart';
import 'package:revivo/core/models/freshness.dart';
import 'package:revivo/features/buyer/domain/cart_item.dart';
import 'package:revivo/features/buyer/domain/coupon.dart';
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
  group('Coupon.discountFor', () {
    test('percent coupon is capped and respects min order', () {
      const c = Coupon(
        code: 'RESCUE15',
        title: '',
        description: '',
        type: CouponType.percent,
        value: 15,
        minOrder: 100,
        maxDiscount: 60,
      );
      // Below min order -> no discount.
      expect(c.discountFor(itemTotal: 80, platformFee: 8), 0);
      // 15% of 200 = 30 (under the cap).
      expect(c.discountFor(itemTotal: 200, platformFee: 8), 30);
      // 15% of 1000 = 150, capped at 60.
      expect(c.discountFor(itemTotal: 1000, platformFee: 8), 60);
    });

    test('flat coupon never exceeds the item total', () {
      const c = Coupon(
        code: 'FIRST50',
        title: '',
        description: '',
        type: CouponType.flat,
        value: 50,
        minOrder: 200,
      );
      expect(c.discountFor(itemTotal: 250, platformFee: 8), 50);
      expect(c.discountFor(itemTotal: 150, platformFee: 8), 0); // under min
    });

    test('fee-waiver coupon returns the platform fee', () {
      const c = Coupon(
        code: 'NOFEE',
        title: '',
        description: '',
        type: CouponType.feeWaiver,
        value: 0,
      );
      expect(c.discountFor(itemTotal: 120, platformFee: 8), 8);
    });
  });

  group('CartBill with coupon', () {
    test('applies the discount and records the code', () {
      final items = [
        CartItem(offer: _offer('a', price: 30), quantityKg: 4), // 120
      ];
      const coupon = Coupon(
        code: 'RESCUE15',
        title: '',
        description: '',
        type: CouponType.percent,
        value: 15,
        minOrder: 100,
        maxDiscount: 60,
      );
      final bill = CartBill.of(items, coupon: coupon);
      expect(bill.itemTotal, 120);
      expect(bill.couponDiscount, 18); // 15% of 120
      expect(bill.couponCode, 'RESCUE15');
      expect(bill.total, 120 + kPlatformFee - 18);
      // Rescue saving (40->30) * 4 = 40, plus coupon 18.
      expect(bill.totalSaved, 40 + 18);
    });

    test('ineligible coupon yields no discount and no code', () {
      final items = [
        CartItem(offer: _offer('a', price: 30), quantityKg: 2), // 60
      ];
      const coupon = Coupon(
        code: 'FIRST50',
        title: '',
        description: '',
        type: CouponType.flat,
        value: 50,
        minOrder: 200,
      );
      final bill = CartBill.of(items, coupon: coupon);
      expect(bill.couponDiscount, 0);
      expect(bill.couponCode, isNull);
      expect(bill.total, 60 + kPlatformFee);
    });
  });
}
