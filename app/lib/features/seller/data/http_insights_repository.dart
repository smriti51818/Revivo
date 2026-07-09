import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../domain/seller_insights.dart';
import 'insights_repository.dart';

/// Live implementation: GET /listings/insights (metrics + Bedrock recs).
class HttpInsightsRepository implements InsightsRepository {
  HttpInsightsRepository(this._api);

  final ApiClient _api;

  @override
  Future<SellerInsightsData> fetch({String period = 'week'}) async {
    final res =
        await _api.get('/listings/insights', query: {'period': period});
    final ins = (res is Map ? res['insights'] as Map? : null) ?? const {};
    final totals = (ins['totals'] as Map?) ?? const {};
    final bands = (ins['bands'] as Map?) ?? const {};
    final moversRaw = (ins['movers'] as List?) ?? const [];
    final earnings = (ins['earnings'] as Map?) ?? const {};
    final impact = (ins['impact'] as Map?) ?? const {};
    final recsRaw =
        (res is Map ? res['recommendations'] as List? : null) ?? const [];

    return SellerInsightsData(
      period: (ins['period'] ?? period).toString(),
      activeListings: (totals['activeListings'] as num?)?.toInt() ?? 0,
      listedKg: asDouble(totals['listedKg']),
      soldKg: asDouble(totals['soldKg']),
      orders: (totals['orders'] as num?)?.toInt() ?? 0,
      revenue: asDouble(totals['revenue']),
      good: (bands['GOOD'] as num?)?.toInt() ?? 0,
      useSoon: (bands['USE_SOON'] as num?)?.toInt() ?? 0,
      rescue: (bands['RESCUE'] as num?)?.toInt() ?? 0,
      movers: [
        for (final m in moversRaw)
          MoverRow(
            vegetable: ((m as Map)['vegetable'] ?? '').toString(),
            kg: asDouble(m['kg']),
            revenue: asDouble(m['revenue']),
            orders: (m['orders'] as num?)?.toInt() ?? 0,
          ),
      ],
      peakHour: (ins['peakHour'] as num?)?.toInt(),
      earnings: EarningsSeries(
        labels: [
          for (final l in (earnings['labels'] as List?) ?? const [])
            l.toString(),
        ],
        values: [
          for (final v in (earnings['values'] as List?) ?? const [])
            asDouble(v),
        ],
      ),
      impact: SellerImpact(
        foodKeptKg: asDouble(impact['foodKeptKg']),
        meals: (impact['meals'] as num?)?.toInt() ?? 0,
        buyerSavings: asDouble(impact['buyerSavings']),
        co2SavedKg: asDouble(impact['co2SavedKg']),
      ),
      recommendations: [
        for (final r in recsRaw)
          InsightRec(
            title: ((r as Map)['title'] ?? '').toString(),
            body: (r['body'] ?? '').toString(),
          ),
      ],
      aiPowered:
          (res is Map ? res['source']?.toString() : null) == 'ai',
    );
  }
}
