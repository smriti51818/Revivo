import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../domain/seller_insights.dart';
import 'insights_repository.dart';

/// Live implementation: GET /listings/insights (metrics + Bedrock recs).
class HttpInsightsRepository implements InsightsRepository {
  HttpInsightsRepository(this._api);

  final ApiClient _api;

  @override
  Future<SellerInsightsData> fetch() async {
    final res = await _api.get('/listings/insights');
    final ins = (res is Map ? res['insights'] as Map? : null) ?? const {};
    final totals = (ins['totals'] as Map?) ?? const {};
    final bands = (ins['bands'] as Map?) ?? const {};
    final moversRaw = (ins['movers'] as List?) ?? const [];
    final recsRaw =
        (res is Map ? res['recommendations'] as List? : null) ?? const [];

    return SellerInsightsData(
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
