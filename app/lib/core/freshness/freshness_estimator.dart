import '../models/freshness.dart';

/// Client-side mirror of the backend freshness engine — gives the vendor an
/// instant band + price preview while listing (no server round-trip). The
/// server value is authoritative once deployed.
class FreshnessEstimate {
  const FreshnessEstimate({
    required this.band,
    required this.timeRange,
    required this.priceFactor,
  });

  final FreshnessBand band;
  final String timeRange;
  final double priceFactor;
}

const Map<String, double> _baseHours = {
  'tomato': 96,
  'potato': 480,
  'onion': 720,
  'spinach': 36,
  'coriander': 36,
  'carrot': 240,
  'bell pepper': 168,
  'capsicum': 168,
  'cabbage': 336,
  'cauliflower': 120,
  'brinjal': 120,
  'okra': 72,
  'green chilli': 168,
  'cucumber': 120,
  'beans': 96,
  'beetroot': 336,
};

const double _defaultHours = 96;

double _storageMultiplier(String storage) => switch (storage) {
      'REFRIGERATED' => 2.5,
      'COLD_STORAGE' => 3.5,
      _ => 1.0,
    };

double _temperatureFactor(double tempC) =>
    (1.0 - (tempC - 25) * 0.03).clamp(0.4, 1.4);

double _baseFor(String vegetable) =>
    _baseHours[vegetable.trim().toLowerCase()] ?? _defaultHours;

String _formatRange(double lowHours, double highHours) {
  if (highHours <= 0) return 'expired';
  if (highHours < 48) return '~${lowHours.round()}-${highHours.round()} h';
  return '~${(lowHours / 24).round()}-${(highHours / 24).round()} days';
}

FreshnessEstimate estimateFreshness({
  required String vegetable,
  required DateTime purchasedAt,
  required String storage,
  double tempC = 28,
  DateTime? now,
}) {
  final total = (_baseFor(vegetable) *
          _storageMultiplier(storage) *
          _temperatureFactor(tempC))
      .clamp(1, double.infinity);
  final elapsed =
      (now ?? DateTime.now()).difference(purchasedAt).inMinutes / 60.0;
  final remaining = total - elapsed;
  final ratio = remaining / total;

  final band = ratio >= 0.5
      ? FreshnessBand.good
      : ratio >= 0.2
          ? FreshnessBand.useSoon
          : FreshnessBand.rescue;
  final factor = switch (band) {
    FreshnessBand.good => 1.0,
    FreshnessBand.useSoon => 0.7,
    FreshnessBand.rescue => 0.4,
  };

  final low = (remaining * 0.85).clamp(0, double.infinity).toDouble();
  final high = (remaining * 1.15).clamp(0, double.infinity).toDouble();

  return FreshnessEstimate(
    band: band,
    timeRange: _formatRange(low, high),
    priceFactor: factor,
  );
}
