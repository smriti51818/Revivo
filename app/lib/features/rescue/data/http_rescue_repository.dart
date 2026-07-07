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

  @override
  Future<Rescue> createRescue({
    required String vendorName,
    required String pickupArea,
    required String vegetable,
    required double quantityKg,
    required FreshnessBand band,
    required String timeRange,
    double distanceKm = 0,
  }) async {
    final res = await _api.post('/rescues', {
      'vendorName': vendorName,
      'pickupArea': pickupArea,
      'vegetable': vegetable,
      'quantityKg': quantityKg,
      'band': band.value,
      'timeRange': timeRange,
      'distanceKm': distanceKm,
    });
    return _fromJson((res['rescue'] as Map).cast<String, dynamic>());
  }

  @override
  Future<Rescue> logMeal(String id,
      {required int meals, String photoKey = ''}) async {
    final res = await _api.post('/rescues/$id/meals', {
      'meals': meals,
      'photoKey': photoKey,
    });
    return _fromJson((res['rescue'] as Map).cast<String, dynamic>());
  }

  @override
  Future<String> explain(String id) async {
    final res = await _api.post('/rescues/$id/explain', const {});
    return (res is Map ? res['explanation']?.toString() : null) ??
        'No explanation available right now.';
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
      mealsServed: j['mealsServed'] == null ? null : asInt(j['mealsServed']),
      mealPhotoKey: j['mealPhotoKey']?.toString(),
    );
  }
}
