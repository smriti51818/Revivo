import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_role.dart';

/// The signed-in user. `idToken` is the Cognito JWT sent to the API; it is null
/// in offline/mock mode.
class Session {
  const Session({
    required this.name,
    required this.email,
    required this.role,
    this.idToken,
    this.userId,
  });

  final String name;
  final String email;
  final UserRole role;
  final String? idToken;
  final String? userId;
}

class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// Offline/mock sign-in (no token).
  void signIn({
    required String name,
    required String email,
    required UserRole role,
  }) {
    state = Session(name: name, email: email, role: role);
  }

  /// Live sign-in backed by Amazon Cognito.
  void setAuthenticated({
    required String name,
    required String email,
    required UserRole role,
    required String idToken,
    required String userId,
  }) {
    state = Session(
      name: name,
      email: email,
      role: role,
      idToken: idToken,
      userId: userId,
    );
  }

  void signOut() => state = null;
}

final sessionProvider =
    NotifierProvider<SessionController, Session?>(SessionController.new);
