import '../domain/seller_insights.dart';

/// Fetches the seller's insights (metrics + recommendations). Swapped for the
/// HTTP implementation once live.
abstract class InsightsRepository {
  Future<SellerInsightsData> fetch();
}

/// Mock insights for offline/demo mode.
class InMemoryInsightsRepository implements InsightsRepository {
  @override
  Future<SellerInsightsData> fetch() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const SellerInsightsData(
      activeListings: 6,
      listedKg: 78,
      soldKg: 41,
      orders: 9,
      revenue: 4820,
      good: 3,
      useSoon: 2,
      rescue: 1,
      movers: [
        MoverRow(vegetable: 'Tomato', kg: 22, revenue: 620, orders: 4),
        MoverRow(vegetable: 'Spinach', kg: 12, revenue: 260, orders: 3),
        MoverRow(vegetable: 'Carrot', kg: 7, revenue: 210, orders: 2),
      ],
      peakHour: 18,
      recommendations: [
        InsightRec(
          title: 'Clear rescue-band stock',
          body: 'You have 1 listing near expiry — discount or route to an '
              'NGO kitchen today.',
        ),
        InsightRec(
          title: 'Restock Tomato',
          body: 'Your best seller: 22 kg sold across 4 orders.',
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
