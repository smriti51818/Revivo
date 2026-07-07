import 'package:flutter_test/flutter_test.dart';
import 'package:revivo/core/models/freshness.dart';
import 'package:revivo/features/seller/domain/listing.dart';

Listing _listing({
  required double totalHours,
  required double remainingHours,
  double basePrice = 40,
  double quantityKg = 10,
}) {
  final now = DateTime.now();
  return Listing(
    id: 'lst_1',
    vegetable: 'Tomato',
    quantityKg: quantityKg,
    basePrice: basePrice,
    recommendedPrice: basePrice, // snapshot; live getters override it
    band: FreshnessBand.good,
    timeRange: '~$remainingHours h',
    storage: StorageCondition.room,
    createdAt: now,
    expiresAt: now.add(Duration(minutes: (remainingHours * 60).round())),
    totalHours: totalHours,
  );
}

void main() {
  test('liveBand tracks the remaining/total ratio, not the stored snapshot', () {
    // 60% of shelf life left → GOOD (≥0.5).
    expect(_listing(totalHours: 100, remainingHours: 60).liveBand(),
        FreshnessBand.good);
    // 30% left → USE_SOON (≥0.2).
    expect(_listing(totalHours: 100, remainingHours: 30).liveBand(),
        FreshnessBand.useSoon);
    // 10% left → RESCUE (<0.2).
    expect(_listing(totalHours: 100, remainingHours: 10).liveBand(),
        FreshnessBand.rescue);
  });

  test('livePricePerKg decays with the band', () {
    final good = _listing(totalHours: 100, remainingHours: 60);
    final useSoon = _listing(totalHours: 100, remainingHours: 30);
    final rescue = _listing(totalHours: 100, remainingHours: 10);
    expect(good.livePricePerKg(), closeTo(40, 0.01)); // ×1.0
    expect(useSoon.livePricePerKg(), closeTo(28, 0.01)); // ×0.7
    expect(rescue.livePricePerKg(), closeTo(16, 0.01)); // ×0.4
  });

  test('atRisk is true only in the Use-soon and Rescue bands', () {
    expect(_listing(totalHours: 100, remainingHours: 60).atRisk(), isFalse);
    expect(_listing(totalHours: 100, remainingHours: 30).atRisk(), isTrue);
    expect(_listing(totalHours: 100, remainingHours: 10).atRisk(), isTrue);
  });

  test('liveValue reflects decay while freshValue stays at market', () {
    final l = _listing(
        totalHours: 100, remainingHours: 10, basePrice: 40, quantityKg: 10);
    expect(l.freshValue, closeTo(400, 0.01)); // 10kg × ₹40
    expect(l.liveValue(), closeTo(160, 0.01)); // 10kg × ₹16 (rescue band)
  });

  test('nextDropAt points at the next band crossing, null once in Rescue', () {
    final now = DateTime.now();
    // 60% left → next drop when it reaches 50% (0.5×100h = 50h remaining).
    final good = _listing(totalHours: 100, remainingHours: 60);
    final drop = good.nextDropAt(now);
    expect(drop, isNotNull);
    expect(drop!.isAfter(now), isTrue);
    // Already in Rescue → no further drop.
    expect(_listing(totalHours: 100, remainingHours: 10).nextDropAt(now), isNull);
  });
}
