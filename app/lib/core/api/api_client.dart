import 'dart:convert';

import 'package:http/http.dart' as http;

/// Raised on a non-2xx API response or a transport error.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

/// Thin authenticated JSON client for the Revivo REST API. The Cognito ID
/// token (from the current session) is sent in the Authorization header, which
/// the API Gateway Cognito authorizer validates.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenGetter,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String? Function() tokenGetter;
  final http.Client _client;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final token = tokenGetter();
    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'Please sign in again.');
    }

    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: query == null || query.isEmpty ? null : query);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token,
    };

    late final http.Response resp;
    try {
      resp = switch (method) {
        'POST' => await _client.post(uri,
            headers: headers, body: json.encode(body ?? const {})),
        'PATCH' => await _client.patch(uri,
            headers: headers, body: json.encode(body ?? const {})),
        'DELETE' => await _client.delete(uri, headers: headers),
        _ => await _client.get(uri, headers: headers),
      };
    } catch (_) {
      throw const ApiException(0, 'Network error. Check your connection.');
    }

    final decoded = resp.body.isEmpty ? null : json.decode(resp.body);
    if (resp.statusCode >= 400) {
      final message = decoded is Map && decoded['error'] != null
          ? decoded['error'].toString()
          : 'Request failed (${resp.statusCode}).';
      throw ApiException(resp.statusCode, message);
    }
    return decoded;
  }
}
