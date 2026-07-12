import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../../../core/notifications/local_notifications.dart';
import '../data/http_notifications_repository.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  final config = ref.read(appConfigProvider);
  if (!config.useLiveApi) return InMemoryNotificationsRepository();
  return HttpNotificationsRepository(ref.read(apiClientProvider));
});

/// The current user's notification feed. The bell watches this for its unread
/// badge; opening the sheet marks everything read.
class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() {
    return ref.read(notificationsRepositoryProvider).fetch();
  }

  Future<void> reload() async {
    final prev = state.valueOrNull ?? const [];
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).fetch(),
    );
    // Fire a device notification for any unread items that weren't in the
    // previous fetch (i.e., genuinely new).
    final current = state.valueOrNull ?? const [];
    final prevIds = prev.map((n) => n.id).toSet();
    for (final n in current) {
      if (!n.read && !prevIds.contains(n.id)) {
        showLocalNotification(title: n.title, body: n.body, id: n.id.hashCode);
      }
    }
  }

  /// Marks everything read server-side, then optimistically flips local state.
  Future<void> markAllRead() async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final n in current)
        AppNotification(
          id: n.id,
          kind: n.kind,
          title: n.title,
          body: n.body,
          read: true,
          createdAt: n.createdAt,
        ),
    ]);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

/// Unread count for the bell badge — 0 while loading or on error.
final unreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.valueOrNull?.where((n) => !n.read).length ?? 0;
});
