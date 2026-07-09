import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Raised on any authentication failure, carrying a user-friendly message.
/// [code] is the short Cognito exception name (e.g. `UserNotConfirmedException`)
/// so callers can branch on it without string-matching [message].
class AuthException implements Exception {
  const AuthException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}

/// Thrown by [CognitoService.signUp] when the account still needs email
/// confirmation before it can sign in — i.e. the pre-sign-up auto-confirm
/// trigger isn't deployed (or wasn't deployed at the time this user signed
/// up). Callers should navigate to a code-entry screen; a fresh code has
/// already been sent by the time this is thrown.
class NeedsConfirmationException implements Exception {
  const NeedsConfirmationException(this.email);
  final String email;
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
      'AuthParameters': {'USERNAME': email.trim().toLowerCase(), 'PASSWORD': password},
    });
    final auth = res['AuthenticationResult'] as Map<String, dynamic>?;
    if (auth == null || auth['IdToken'] == null) {
      throw const AuthException('Login failed. Please try again.');
    }
    return _resultFrom(auth);
  }

  /// Signs in and makes the account's role match [desiredRole] (the persona the
  /// user just chose). If the stored `custom:role` differs — e.g. this email
  /// was first registered as another role — it is updated and a fresh token is
  /// fetched so the claim is correct everywhere. Used by the registration flow,
  /// where the selected role is authoritative.
  Future<AuthResult> signInWithRole({
    required String email,
    required String password,
    required String desiredRole,
  }) async {
    var result = await signIn(email: email, password: password);
    if (result.role == desiredRole) return result;
    try {
      await _call('UpdateUserAttributes', {
        'AccessToken': result.accessToken,
        'UserAttributes': [
          {'Name': 'custom:role', 'Value': desiredRole},
        ],
      });
      result = await signIn(email: email, password: password);
    } catch (_) {
      // If the attribute can't be updated (e.g. write perms not deployed yet),
      // the caller still navigates by the selected role for a smooth demo.
    }
    return result;
  }

  /// Creates an account then signs in. If the pre-sign-up trigger is deployed
  /// the user is auto-confirmed and this returns immediately signed in;
  /// otherwise it throws [NeedsConfirmationException] so the caller can show
  /// a code-entry screen. Also recovers an account stuck UNCONFIRMED from a
  /// previous attempt by resending its code instead of failing outright.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final res = await _call('SignUp', {
        'ClientId': _config.userPoolClientId,
        'Username': email.trim().toLowerCase(),
        'Password': password,
        'UserAttributes': [
          {'Name': 'email', 'Value': email.trim().toLowerCase()},
          {'Name': 'name', 'Value': name},
          {'Name': 'custom:role', 'Value': role},
        ],
      });
      if (res['UserConfirmed'] != true) {
        throw NeedsConfirmationException(email.trim().toLowerCase());
      }
      return signInWithRole(
        email: email,
        password: password,
        desiredRole: role,
      );
    } on AuthException catch (e) {
      if (e.code != 'UsernameExistsException') rethrow;
      // Resend succeeds only for an account still UNCONFIRMED from an earlier
      // attempt — recover it into the code screen. If resend fails, the account
      // is already registered and confirmed, so tell the user to log in.
      try {
        await resendConfirmationCode(email: email);
      } on AuthException {
        throw const AuthException(
          'This email is already registered. Please log in instead.',
          code: 'UsernameExistsException',
        );
      }
      throw NeedsConfirmationException(email.trim().toLowerCase());
    }
  }

  /// Confirms a pending sign-up with the code emailed by Cognito.
  Future<void> confirmSignUp({
    required String email,
    required String code,
  }) async {
    await _call('ConfirmSignUp', {
      'ClientId': _config.userPoolClientId,
      'Username': email.trim().toLowerCase(),
      'ConfirmationCode': code.trim(),
    });
  }

  /// Requests a fresh confirmation code for an unconfirmed account.
  Future<void> resendConfirmationCode({required String email}) async {
    await _call('ResendConfirmationCode', {
      'ClientId': _config.userPoolClientId,
      'Username': email.trim().toLowerCase(),
    });
  }

  Future<Map<String, dynamic>> _call(
    String action,
    Map<String, dynamic> body,
  ) async {
    late final http.Response resp;
    try {
      resp = await _client
          .post(
            Uri.parse(_config.cognitoIdpUrl),
            headers: {
              'Content-Type': 'application/x-amz-json-1.1',
              'X-Amz-Target': 'AWSCognitoIdentityProviderService.$action',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const AuthException(
          'Network error. Check your connection and try again.');
    }

    final decoded = resp.body.isEmpty
        ? <String, dynamic>{}
        : json.decode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 400) {
      final rawType = (decoded['__type'] ?? '').toString();
      final idx = rawType.lastIndexOf('#');
      final code = idx == -1 ? rawType : rawType.substring(idx + 1);
      throw AuthException(
        _friendly(decoded),
        code: code.isEmpty ? null : code,
      );
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
    if (type.contains('UserNotConfirmed')) {
      return 'Please verify your email to continue.';
    }
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
    if (type.contains('InvalidParameter') &&
        msg.toLowerCase().contains('confirm')) {
      return 'An account with that email already exists. Please log in.';
    }
    if (type.contains('CodeMismatch')) {
      return 'That code is incorrect. Please check and try again.';
    }
    if (type.contains('ExpiredCode')) {
      return 'That code has expired. Tap "Resend" for a new one.';
    }
    if (type.contains('InvalidParameter') && msg.isNotEmpty) return msg;
    return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
  }
}
