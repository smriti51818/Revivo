import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';

const _kName = 'session_name';
const _kEmail = 'session_email';
const _kRole = 'session_role';
const _kIdToken = 'session_id_token';
const _kRefreshToken = 'session_refresh_token';
const _kUserId = 'session_user_id';
const _kPhone = 'session_phone';

/// The signed-in user. `idToken` is the Cognito JWT sent to the API; it is null
/// in offline/mock mode.
class Session {
  const Session({
    required this.name,
    required this.email,
    required this.role,
    this.idToken,
    this.refreshToken,
    this.userId,
    this.phone,
  });

  final String name;
  final String email;
  final UserRole role;
  final String? idToken;
  final String? refreshToken;
  final String? userId;
  final String? phone;
}

class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// Restore session from persistent storage. Call once at app startup.
  Future<bool> tryRestore() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kEmail);
    final roleName = prefs.getString(_kRole);
    if (email == null || roleName == null) return false;

    final role = UserRole.values.where((r) => r.value == roleName).firstOrNull;
    if (role == null) return false;

    state = Session(
      name: prefs.getString(_kName) ?? '',
      email: email,
      role: role,
      idToken: prefs.getString(_kIdToken),
      refreshToken: prefs.getString(_kRefreshToken),
      userId: prefs.getString(_kUserId),
      phone: prefs.getString(_kPhone),
    );
    return true;
  }

  /// Offline/mock sign-in (no token).
  void signIn({
    required String name,
    required String email,
    required UserRole role,
  }) {
    state = Session(name: name, email: email, role: role);
    _persist();
  }

  /// Live sign-in backed by Amazon Cognito.
  void setAuthenticated({
    required String name,
    required String email,
    required UserRole role,
    required String idToken,
    required String userId,
    String? refreshToken,
    String? phone,
  }) {
    state = Session(
      name: name,
      email: email,
      role: role,
      idToken: idToken,
      refreshToken: refreshToken,
      userId: userId,
      phone: phone,
    );
    _persist();
  }

  void updatePhone(String phone) {
    if (state == null) return;
    state = Session(
      name: state!.name,
      email: state!.email,
      role: state!.role,
      idToken: state!.idToken,
      refreshToken: state!.refreshToken,
      userId: state!.userId,
      phone: phone,
    );
    _persist();
  }

  Future<void> signOut() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kIdToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kPhone);
  }

  Future<void> _persist() async {
    final s = state;
    if (s == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, s.name);
    await prefs.setString(_kEmail, s.email);
    await prefs.setString(_kRole, s.role.value);
    if (s.idToken != null) await prefs.setString(_kIdToken, s.idToken!);
    if (s.refreshToken != null) {
      await prefs.setString(_kRefreshToken, s.refreshToken!);
    }
    if (s.userId != null) await prefs.setString(_kUserId, s.userId!);
    if (s.phone != null) await prefs.setString(_kPhone, s.phone!);
  }
}

final sessionProvider =
    NotifierProvider<SessionController, Session?>(SessionController.new);
