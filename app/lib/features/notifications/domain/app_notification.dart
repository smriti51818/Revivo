import 'package:flutter/material.dart';

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

  IconData get icon => switch (kind) {
        'ORDER' => Icons.receipt_long_outlined,
        'RESCUE' => Icons.volunteer_activism_outlined,
        _ => Icons.notifications_none_rounded,
      };
}
