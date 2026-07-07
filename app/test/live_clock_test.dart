import 'package:flutter_test/flutter_test.dart';
import 'package:revivo/core/format.dart';
import 'package:revivo/core/freshness/live_clock.dart';
import 'package:revivo/core/models/freshness.dart';
import 'package:revivo/features/buyer/domain/offer.dart';

void main() {
  group('formatCountdown', () {
    test('renders days, hours, minutes, seconds by magnitude', () {
      expect(formatCountdown(const Duration(days: 2, hours: 4)), '2d 4h');
      expect(formatCountdown(const Duration(hours: 5, minutes: 12)), '5h 12m');
      expect(formatCountdown(const Duration(minutes: 8, seconds: 30)), '8m 30s');
    });

    test('reports Expired once the window has closed', () {
      expect(formatCountdown(Duration.zero), 'Expired');
      expect(formatCountdown(const Duration(seconds: -10)), 'Expired');
    });
  });

  group('LiveClock band + price decay', () {
    final now = DateTime(2026, 1, 1, 12);

    test('mirrors the backend band thresholds as the ratio falls', () {
      // total 100h; remaining 60h -> ratio .6 GOOD, 30h -> .3 USE_SOON,
      // 10h -> .1 RESCUE.
      expect(
        LiveClock.band(
            expiresAt: now.add(const Duration(hours: 60)),
            totalHours: 100,
            now: now),
        FreshnessBand.good,
      );
      expect(
        LiveClock.band(
            expiresAt: now.add(const Duration(hours: 30)),
            totalHours: 100,
            now: now),
        FreshnessBand.useSoon,
      );
      expect(
        LiveClock.band(
            expiresAt: now.add(const Duration(hours: 10)),
            totalHours: 100,
            now: now),
        FreshnessBand.rescue,
      );
    });

    test('price scales by the live band factor', () {
      // market 40; USE_SOON factor 0.7 -> 28.
      final price = LiveClock.price(
        marketPrice: 40,
        expiresAt: now.add(const Duration(hours: 30)),
        totalHours: 100,
        now: now,
      );
      expect(price, 28);
    });
  });

  group('Offer live getters', () {
    final now = DateTime(2026, 1, 1, 12);

    Offer offer({required int remainingH, required double totalH}) => Offer(
          id: 'o1',
          vendorName: 'V',
          vegetable: 'Tomato',
          availableKg: 10,
          marketPrice: 40,
          offerPrice: 40,
          band: FreshnessBand.good,
          timeRange: '',
          distanceKm: 0,
          expiresAt: now.add(Duration(hours: remainingH)),
          totalHours: totalH,
        );

    test('rescue-band offer is deeply discounted and flagged live', () {
      final o = offer(remainingH: 10, totalH: 100);
      expect(o.liveBand(now), FreshnessBand.rescue);
      expect(o.livePrice(now), 16); // 40 * 0.4
      expect(o.liveSavingsPct(now), 60);
    });

    test('falls back to the snapshot when there is no clock data', () {
      const o = Offer(
        id: 'o2',
        vendorName: 'V',
        vegetable: 'Onion',
        availableKg: 5,
        marketPrice: 30,
        offerPrice: 21,
        band: FreshnessBand.useSoon,
        timeRange: '~1 day',
        distanceKm: 0,
      );
      expect(o.hasClock, isFalse);
      expect(o.livePrice(now), 21);
      expect(o.liveBand(now), FreshnessBand.useSoon);
    });

    test('marks an offer expired once its window closes', () {
      final o = offer(remainingH: -1, totalH: 100);
      expect(o.isExpired(now), isTrue);
    });
  });
}
