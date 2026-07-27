import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../../../core/models/freshness.dart';
import '../domain/freshness_analysis.dart';
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
    // Prefer the key uploaded at capture time; only upload here as a fallback.
    final imageKey = (draft.imageKey != null && draft.imageKey!.isNotEmpty)
        ? draft.imageKey!
        : await uploadPhoto(draft.imagePath ?? '');
    final res = await _api.post('/listings', {
      'vegetable': draft.vegetable,
      'quantityKg': draft.quantityKg,
      'storage': draft.storage.value,
      'purchasedAt': purchased.millisecondsSinceEpoch ~/ 1000,
      'tempC': draft.tempC ?? 28,
      'imageKey': imageKey,
    });
    final created = _fromJson((res['listing'] as Map).cast<String, dynamic>());
    if (draft.imagePath != null && draft.imagePath!.isNotEmpty) {
      return created.copyWith(imagePath: draft.imagePath);
    }
    return created;
  }

  @override
  Future<Listing> updateStock(String id, double quantityKg,
      {String? imageKey}) async {
    final body = <String, dynamic>{'quantityKg': quantityKg};
    if (imageKey != null && imageKey.isNotEmpty) body['imageKey'] = imageKey;
    final res = await _api.patch('/listings/$id', body);
    return _fromJson((res['listing'] as Map).cast<String, dynamic>());
  }

  @override
  Future<void> deleteListing(String id) async {
    await _api.delete('/listings/$id');
  }

  @override
  Future<String> uploadPhoto(String path) async {
    if (path.isEmpty) return '';
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
    } catch (e) {
      debugPrint('uploadPhoto error: $e');
      return '';
    }
  }

  @override
  Future<String?> identify(String imageKey) async {
    if (imageKey.isEmpty) return null;
    try {
      final res = await _api.post('/listings/identify', {'imageKey': imageKey});
      final veg = (res is Map ? res['vegetable'] : null)?.toString();
      return (veg == null || veg.isEmpty) ? null : veg;
    } catch (e) {
      debugPrint('identify error: $e');
      return null;
    }
  }

  @override
  Future<FreshnessAnalysis> analyze({
    required String vegetable,
    required double quantityKg,
    required StorageCondition storage,
    required DateTime purchasedAt,
  }) async {
    final res = await _api.post('/listings/analyze', {
      'vegetable': vegetable,
      'quantityKg': quantityKg,
      'storage': storage.value,
      'purchasedAt': purchasedAt.millisecondsSinceEpoch ~/ 1000,
      'tempC': 28,
    });
    return FreshnessAnalysis(
      band: FreshnessBand.fromValue(res['band']?.toString()),
      timeRange: (res['timeRange'] ?? '').toString(),
      marketPrice: asDouble(res['marketPrice']),
      recommendedPrice: asDouble(res['recommendedPrice']),
    );
  }

  Listing _fromJson(Map<String, dynamic> j) {
    final expiry = j['expiryEpoch'];
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
      expiresAt: expiry is num ? epochToDate(expiry) : null,
      totalHours: j['totalHours'] == null ? null : asDouble(j['totalHours']),
    );
  }
}
