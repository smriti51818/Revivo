import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../../../core/models/freshness.dart';
import '../domain/rescue.dart';
import 'rescue_repository.dart';

/// Live implementation backed by the REST API:
/// GET /rescues (board) and POST /rescues/{id} (lifecycle transitions).
class HttpRescueRepository implements RescueRepository {
  HttpRescueRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Rescue>> fetchRescues() async {
    final res = await _api.get('/rescues');
    final items = (res is Map ? res['rescues'] as List? : null) ?? const [];
    return items
        .map((e) => _fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Rescue> updateStatus(
    String id, {
    required RescueStatus status,
    String? ngoName,
  }) async {
    final body = <String, dynamic>{'action': _actionFor(status)};
    if (ngoName != null) body['ngoName'] = ngoName;
    final res = await _api.post('/rescues/$id', body);
    return _fromJson((res['rescue'] as Map).cast<String, dynamic>());
  }

  /// Maps the target status to the server-side lifecycle action.
  String _actionFor(RescueStatus status) => switch (status) {
        RescueStatus.accepted => 'ACCEPT',
        RescueStatus.assigned => 'CLAIM',
        RescueStatus.pickedUp => 'PICKUP',
        RescueStatus.delivered => 'DELIVER',
        RescueStatus.offered => 'ACCEPT',
      };

  Rescue _fromJson(Map<String, dynamic> j) {
    return Rescue(
      id: (j['id'] ?? '').toString(),
      vendorName: (j['vendorName'] ?? '').toString(),
      pickupArea: (j['pickupArea'] ?? '').toString(),
      vegetable: (j['vegetable'] ?? '').toString(),
      quantityKg: asDouble(j['quantityKg']),
      band: FreshnessBand.fromValue(j['band']?.toString()),
      timeRange: (j['timeRange'] ?? '').toString(),
      distanceKm: asDouble(j['distanceKm']),
      status: RescueStatus.fromValue(j['status']?.toString()),
      ngoName: j['ngoName']?.toString(),
    );
  }
}
