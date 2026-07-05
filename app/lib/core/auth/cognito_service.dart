import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Raised on any authentication failure, carrying a user-friendly message.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The outcome of a successful sign-in: tokens + decoded identity claims.
class AuthResult {
  const AuthResult({
    required this.idToken,
    required this.accessToken,
    required this.refreshToken,
    required this.sub,
    required this.email,
    required this.name,
    required this.role,
  });

  final String idToken;
  final String accessToken;
  final String refreshToken;
  final String sub;
  final String email;
  final String name;
  final String? role;
}

/// Minimal Amazon Cognito client using the Identity Provider JSON API over
/// HTTPS (USER_PASSWORD_AUTH). No native SDK — works on every Flutter target.
/// The app client has no secret, so no SECRET_HASH is required.
class CognitoService {
  CognitoService(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  final AppConfig _config;
  final http.Client _client;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _call('InitiateAuth', {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': _config.userPoolClientId,
      'AuthParameters': {'USERNAME': email.trim(), 'PASSWORD': password},
    });
    final auth = res['AuthenticationResult'] as Map<String, dynamic>?;
    if (auth == null || auth['IdToken'] == null) {
      throw const AuthException('Login failed. Please try again.');
    }
    return _resultFrom(auth);
  }

  /// Creates an account then signs in. The pre-sign-up trigger auto-confirms
  /// the user, so no emailed code step is needed.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    await _call('SignUp', {
      'ClientId': _config.userPoolClientId,
      'Username': email.trim(),
      'Password': password,
      'UserAttributes': [
        {'Name': 'email', 'Value': email.trim()},
        {'Name': 'name', 'Value': name},
        {'Name': 'custom:role', 'Value': role},
      ],
    });
    return signIn(email: email, password: password);
  }

  Future<Map<String, dynamic>> _call(
    String action,
    Map<String, dynamic> body,
  ) async {
    late final http.Response resp;
    try {
      resp = await _client.post(
        Uri.parse(_config.cognitoIdpUrl),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.$action',
        },
        body: json.encode(body),
      );
    } catch (_) {
      throw const AuthException(
          'Network error. Check your connection and try again.');
    }

    final decoded = resp.body.isEmpty
        ? <String, dynamic>{}
        : json.decode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 400) {
      throw AuthException(_friendly(decoded));
    }
    return decoded;
  }

  AuthResult _resultFrom(Map<String, dynamic> auth) {
    final idToken = auth['IdToken'] as String;
    final claims = _decodeJwt(idToken);
    return AuthResult(
      idToken: idToken,
      accessToken: auth['AccessToken'] as String? ?? '',
      refreshToken: auth['RefreshToken'] as String? ?? '',
      sub: claims['sub']?.toString() ?? '',
      email: claims['email']?.toString() ?? '',
      name: claims['name']?.toString() ?? '',
      role: claims['custom:role']?.toString(),
    );
  }

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    payload = payload.padRight((payload.length + 3) & ~3, '=');
    final decoded = utf8.decode(base64.decode(payload));
    return json.decode(decoded) as Map<String, dynamic>;
  }

  String _friendly(Map<String, dynamic> body) {
    final type = (body['__type'] ?? '').toString();
    final msg = (body['message'] ?? body['Message'] ?? '').toString();
    if (type.contains('NotAuthorized')) return 'Incorrect email or password.';
    if (type.contains('UserNotFound')) {
      return 'No account found for that email.';
    }
    if (type.contains('UsernameExists')) {
      return 'An account with that email already exists.';
    }
    if (type.contains('InvalidPassword')) {
      return 'Password needs 8+ characters with a lowercase letter and a number.';
    }
    if (type.contains('TooManyRequests') || type.contains('LimitExceeded')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (type.contains('InvalidParameter') && msg.isNotEmpty) return msg;
    return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
  }
}
