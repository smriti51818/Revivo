import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../domain/impact.dart';
import 'impact_repository.dart';

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

/// Live implementation backed by GET /impact (aggregated server-side).
class HttpImpactRepository implements ImpactRepository {
  HttpImpactRepository(this._api);

  final ApiClient _api;

  @override
  Future<ImpactData> fetchImpact() async {
    final res = await _api.get('/impact');
    final s = ((res is Map ? res['summary'] : null) as Map? ?? const {})
        .cast<String, dynamic>();
    final board = (res is Map ? res['leaderboard'] as List? : null) ?? const [];

    return ImpactData(
      summary: ImpactSummary(
        kgRescued: asDouble(s['kgRescued']),
        mealsServed: _asInt(s['mealsServed']),
        co2SavedKg: asDouble(s['co2SavedKg']),
        moneySaved: asDouble(s['moneySaved']),
        activeVendors: _asInt(s['activeVendors']),
        activeNgos: _asInt(s['activeNgos']),
        mealsGoal: _asInt(s['mealsGoal']) == 0 ? 5000 : _asInt(s['mealsGoal']),
      ),
      leaderboard: board.map((e) {
        final m = (e as Map).cast<String, dynamic>();
        return LeaderboardEntry(
          rank: _asInt(m['rank']),
          name: (m['name'] ?? '').toString(),
          role: (m['role'] ?? '').toString(),
          kg: asDouble(m['kg']),
          meals: _asInt(m['meals']),
        );
      }).toList(),
    );
  }
}
