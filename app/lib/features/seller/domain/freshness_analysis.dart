import '../../../core/models/freshness.dart';

/// Result of the server-side freshness analysis (POST /listings/analyze).
/// The band, honest time window, and fair price are computed by Revivo's
/// freshness engine on AWS — not on the device.
class FreshnessAnalysis {
  const FreshnessAnalysis({
    required this.band,
    required this.timeRange,
    required this.marketPrice,
    required this.recommendedPrice,
  });

  final FreshnessBand band;
  final String timeRange;

  /// Fair market rate per kg for the produce (before the freshness discount).
  final double marketPrice;

  /// Revivo's suggested price per kg (market x freshness factor).
  final double recommendedPrice;

  /// Per-kg saving a buyer gets versus the market rate.
  double get savingPerKg =>
      (marketPrice - recommendedPrice).clamp(0, marketPrice).toDouble();
}
