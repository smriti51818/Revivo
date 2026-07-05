import '../domain/app_notification.dart';

/// Reads the current user's notification feed and marks it read. Swapped for
/// the HTTP implementation once live.
abstract class NotificationsRepository {
  Future<List<AppNotification>> fetch();
  Future<void> markAllRead();
}

/// Mock feed for offline/demo mode — a couple of seeded notifications the
/// "mark read" action clears.
class InMemoryNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> _items = [
    AppNotification(
      id: 'ntf_1',
      kind: 'ORDER',
      title: 'New order received',
      body: 'Hotel Ashok ordered 6 kg Tomatoes',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    AppNotification(
      id: 'ntf_2',
      kind: 'ORDER',
      title: 'New order received',
      body: 'Green Leaf Cafe ordered 3 kg Spinach',
      read: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Future<List<AppNotification>> fetch() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> markAllRead() async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (var i = 0; i < _items.length; i++) {
      final n = _items[i];
      if (!n.read) {
        _items[i] = AppNotification(
          id: n.id,
          kind: n.kind,
          title: n.title,
          body: n.body,
          read: true,
          createdAt: n.createdAt,
        );
      }
    }
  }
}
