import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../api/providers.dart';

/// Uploads a local image to S3 via a presigned PUT (POST /uploads → PUT bytes)
/// and returns the object key. Best-effort: returns '' on any failure or when
/// running offline, so callers can proceed without a photo.
class ImageUploader {
  const ImageUploader(this._api);

  final ApiClient? _api;

  Future<String> upload(String path) async {
    final api = _api;
    if (api == null || path.isEmpty) return '';
    try {
      final bytes = await File(path).readAsBytes();
      final res = await api.post('/uploads', const {});
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
}

final imageUploaderProvider = Provider<ImageUploader>((ref) {
  final config = ref.read(appConfigProvider);
  return ImageUploader(
      config.useLiveApi ? ref.read(apiClientProvider) : null);
});
