/// One AI/heuristic recommendation shown on the insights screen.
class InsightRec {
  const InsightRec({required this.title, required this.body});
  final String title;
  final String body;
}

/// A bucketed earnings series for the overview chart — labels + rupee values,
/// both computed on AWS for the selected period (week/month/year).
class EarningsSeries {
  const EarningsSeries({required this.labels, required this.values});
  final List<String> labels;
  final List<double> values;

  bool get hasData => values.any((v) => v > 0);

  static const empty = EarningsSeries(labels: [], values: []);
}

/// Meals + savings the seller created, computed on AWS with the same constants
/// as the network-wide impact page (no client-side guessing).
class SellerImpact {
  const SellerImpact({
    required this.foodKeptKg,
    required this.meals,
    required this.buyerSavings,
    required this.co2SavedKg,
  });
  final double foodKeptKg;
  final int meals;
  final double buyerSavings;
  final double co2SavedKg;

  static const empty =
      SellerImpact(foodKeptKg: 0, meals: 0, buyerSavings: 0, co2SavedKg: 0);
}

/// A top-selling vegetable row (real, from the seller's orders).
class MoverRow {
  const MoverRow({
    required this.vegetable,
    required this.kg,
    required this.revenue,
    required this.orders,
  });
  final String vegetable;
  final double kg;
  final double revenue;
  final int orders;
}

/// Seller insights computed on AWS from real listings + orders, plus Bedrock
/// (or fallback) recommendations.
class SellerInsightsData {
  const SellerInsightsData({
    required this.period,
    required this.activeListings,
    required this.listedKg,
    required this.soldKg,
    required this.orders,
    required this.revenue,
    required this.good,
    required this.useSoon,
    required this.rescue,
    required this.movers,
    required this.peakHour,
    required this.earnings,
    required this.impact,
    required this.recommendations,
    required this.aiPowered,
  });

  final String period;
  final int activeListings;
  final double listedKg;
  final double soldKg;
  final int orders;
  final double revenue;
  final int good;
  final int useSoon;
  final int rescue;
  final List<MoverRow> movers;
  final int? peakHour;
  final EarningsSeries earnings;
  final SellerImpact impact;
  final List<InsightRec> recommendations;
  final bool aiPowered;

  bool get hasActivity => orders > 0 || activeListings > 0;
}
