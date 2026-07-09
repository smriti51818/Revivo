import '../domain/seller_insights.dart';

/// Fetches the seller's insights (metrics + recommendations) for a period
/// ('week' | 'month' | 'year'). Swapped for the HTTP implementation once live.
abstract class InsightsRepository {
  Future<SellerInsightsData> fetch({String period = 'week'});
}

/// Mock insights for offline/demo mode. Everything is *derived* from a small
/// synthetic order set and scaled by the selected period, so the numbers move
/// with the filter instead of being frozen literals.
class InMemoryInsightsRepository implements InsightsRepository {
  @override
  Future<SellerInsightsData> fetch({String period = 'week'}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Period scaling + chart buckets mirror the backend's shape.
    final (factor, labels) = switch (period) {
      'month' => (4.2, const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4']),
      'year' => (
          46.0,
          const [
            'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan',
            'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'
          ]
        ),
      _ => (1.0, const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']),
    };

    const baseDaily = [420.0, 260.0, 610.0, 300.0, 880.0, 540.0, 690.0];
    final values = [
      for (var i = 0; i < labels.length; i++)
        (baseDaily[i % baseDaily.length] * (period == 'week' ? 1 : factor / 2))
            .roundToDouble(),
    ];
    final revenue = values.fold<double>(0, (s, v) => s + v);
    final soldKg = (revenue / 28).roundToDouble();
    final orders = (9 * factor).round();

    return SellerInsightsData(
      period: period,
      activeListings: 6,
      listedKg: 78,
      soldKg: soldKg,
      orders: orders,
      revenue: revenue,
      good: 3,
      useSoon: 2,
      rescue: 1,
      movers: [
        MoverRow(
            vegetable: 'Tomato',
            kg: (22 * factor).roundToDouble(),
            revenue: (620 * factor).roundToDouble(),
            orders: (4 * factor).round()),
        MoverRow(
            vegetable: 'Spinach',
            kg: (12 * factor).roundToDouble(),
            revenue: (260 * factor).roundToDouble(),
            orders: (3 * factor).round()),
        MoverRow(
            vegetable: 'Carrot',
            kg: (7 * factor).roundToDouble(),
            revenue: (210 * factor).roundToDouble(),
            orders: (2 * factor).round()),
      ],
      peakHour: 18,
      earnings: EarningsSeries(labels: labels, values: values),
      impact: SellerImpact(
        foodKeptKg: soldKg,
        meals: (soldKg * 2.5).round(),
        buyerSavings: (revenue * 0.28).roundToDouble(),
        co2SavedKg: (soldKg * 2.5).roundToDouble(),
      ),
      recommendations: const [
        InsightRec(
          title: 'Clear rescue-band stock',
          body: 'You have 1 listing near expiry — discount or route to an '
              'NGO kitchen today.',
        ),
        InsightRec(
          title: 'Restock Tomato',
          body: 'Your best seller keeps moving — keep it in stock.',
        ),
        InsightRec(
          title: 'List before peak demand',
          body: 'Most orders land around 6–9 PM — list a few hours earlier.',
        ),
      ],
      aiPowered: false,
    );
  }
}
