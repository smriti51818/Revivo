/// One AI/heuristic recommendation shown on the insights screen.
class InsightRec {
  const InsightRec({required this.title, required this.body});
  final String title;
  final String body;
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
    required this.recommendations,
    required this.aiPowered,
  });

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
  final List<InsightRec> recommendations;
  final bool aiPowered;

  bool get hasActivity => orders > 0 || activeListings > 0;
}
