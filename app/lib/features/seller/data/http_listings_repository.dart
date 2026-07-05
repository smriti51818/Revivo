import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../../../core/models/freshness.dart';
import '../domain/listing.dart';
import 'listings_repository.dart';

/// Live implementation backed by the REST API:
/// GET /listings/mine (seller dashboard) and POST /listings (publish).
class HttpListingsRepository implements ListingsRepository {
  HttpListingsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Listing>> fetchListings() async {
    final res = await _api.get('/listings/mine');
    final items = (res is Map ? res['listings'] as List? : null) ?? const [];
    return items
        .map((e) => _fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Listing> createListing(Listing draft) async {
    final purchased = draft.purchasedAt ?? draft.createdAt;
    final imageKey = await _uploadPhoto(draft.imagePath);
    final res = await _api.post('/listings', {
      'vegetable': draft.vegetable,
      'quantityKg': draft.quantityKg,
      'basePrice': draft.basePrice,
      'storage': draft.storage.value,
      'purchasedAt': purchased.millisecondsSinceEpoch ~/ 1000,
      'tempC': draft.tempC ?? 28,
      'imageKey': imageKey,
    });
    return _fromJson((res['listing'] as Map).cast<String, dynamic>());
  }

  /// Uploads the picked photo to S3 via a presigned PUT and returns its key.
  /// Best-effort: any failure returns '' so the listing still publishes.
  Future<String> _uploadPhoto(String? path) async {
    if (path == null || path.isEmpty) return '';
    try {
      final bytes = await File(path).readAsBytes();
      final res = await _api.post('/uploads', const {});
      final uploadUrl = (res['uploadUrl'] ?? '').toString();
      final key = (res['key'] ?? '').toString();
      if (uploadUrl.isEmpty || key.isEmpty) return '';
      final put = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: bytes,
      );
      return put.statusCode < 300 ? key : '';
    } catch (_) {
      return '';
    }
  }

  Listing _fromJson(Map<String, dynamic> j) {
    return Listing(
      id: (j['id'] ?? '').toString(),
      vegetable: (j['vegetable'] ?? '').toString(),
      quantityKg: asDouble(j['quantityKg']),
      basePrice: asDouble(j['basePrice']),
      recommendedPrice: asDouble(j['recommendedPrice']),
      band: FreshnessBand.fromValue(j['band']?.toString()),
      timeRange: (j['timeRange'] ?? '').toString(),
      storage: StorageCondition.fromValue(j['storage']?.toString()),
      createdAt: epochToDate(j['createdAt']),
      imageUrl: (j['imageUrl'] ?? '').toString(),
    );
  }
}
