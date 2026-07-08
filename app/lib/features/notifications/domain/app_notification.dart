import 'package:hugeicons/hugeicons.dart';

/// An in-app notification (e.g. "New order received"). Written server-side by
/// the Streams notifier; read via GET /notifications.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String kind; // ORDER | RESCUE | INFO
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  dynamic get icon => switch (kind) {
        'ORDER' => HugeIcons.strokeRoundedReceiptText,
        'RESCUE' => HugeIcons.strokeRoundedHandHelping,
        _ => HugeIcons.strokeRoundedNotification01,
      };
}
