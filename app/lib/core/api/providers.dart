import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/cognito_service.dart';
import '../config/app_config.dart';
import '../session/session_controller.dart';
import 'api_client.dart';

final appConfigProvider = Provider<AppConfig>((_) => AppConfig.current);

final cognitoServiceProvider = Provider<CognitoService>(
  (ref) => CognitoService(ref.read(appConfigProvider)),
);

/// Authenticated API client. Reads the ID token from the session at call time,
/// so it always uses the current credentials.
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.read(appConfigProvider);
  return ApiClient(
    baseUrl: config.apiBaseUrl,
    tokenGetter: () => ref.read(sessionProvider)?.idToken,
  );
});
