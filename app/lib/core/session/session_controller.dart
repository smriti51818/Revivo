import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_role.dart';

/// The signed-in user. In M1 this is set locally on login;
/// M3 replaces the source with Amazon Cognito (JWT + custom:role).
class Session {
  const Session({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final UserRole role;
}

class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;

  void signIn({
    required String name,
    required String email,
    required UserRole role,
  }) {
    state = Session(name: name, email: email, role: role);
  }

  void signOut() => state = null;
}

final sessionProvider =
    NotifierProvider<SessionController, Session?>(SessionController.new);
