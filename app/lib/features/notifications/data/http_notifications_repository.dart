import '../../../core/api/api_client.dart';
import '../../../core/api/json_utils.dart';
import '../domain/app_notification.dart';
import 'notifications_repository.dart';

/// Live implementation: GET /notifications and POST /notifications/read.
class HttpNotificationsRepository implements NotificationsRepository {
  HttpNotificationsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AppNotification>> fetch() async {
    final res = await _api.get('/notifications');
    final items =
        (res is Map ? res['notifications'] as List? : null) ?? const [];
    return items
        .map((e) => _fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> markAllRead() => _api.post('/notifications/read', const {});

  AppNotification _fromJson(Map<String, dynamic> j) {
    return AppNotification(
      id: (j['id'] ?? '').toString(),
      kind: (j['kind'] ?? 'INFO').toString(),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      read: j['read'] == true,
      createdAt: epochToDate(j['createdAt']),
    );
  }
}
