import '../../../core/models/freshness.dart';

/// Result of the server-side freshness analysis (POST /listings/analyze).
/// The band, honest time window, and fair price are computed by Revivo's
/// freshness engine on AWS — not on the device.
class FreshnessAnalysis {
  const FreshnessAnalysis({
    required this.band,
    required this.timeRange,
    required this.recommendedPrice,
  });

  final FreshnessBand band;
  final String timeRange;
  final double recommendedPrice;
}
