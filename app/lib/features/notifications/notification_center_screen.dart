import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/user_role.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import 'application/notifications_providers.dart';
import 'domain/app_notification.dart';

enum _Cat {
  all('All', null),
  orders('Orders', 'ORDER'),
  rescues('Rescues', 'RESCUE'),
  system('System', 'INFO');

  const _Cat(this.label, this.kind);
  final String label;
  final String? kind;
}

/// A full-page notification center with category tabs — the durable home for
/// alerts, versus the bell's quick-glance sheet. Opening it clears the unread
/// badge; each alert taps through to where it happened.
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  _Cat _cat = _Cat.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(notificationsProvider.notifier).reload();
      await ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  void _open(AppNotification n) {
    final role = ref.read(sessionProvider)?.role;
    switch (n.kind) {
      case 'ORDER':
        context.go(role == UserRole.vendor ? '/seller/orders' : '/buyer/orders');
      case 'RESCUE':
        if (role == UserRole.cook) context.go('/cook/inbox');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: Column(
          children: [
            _tabs(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificationsProvider.notifier).reload(),
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text('Could not load: $e')),
                    ),
                  ]),
                  data: (items) {
                    final list = _cat.kind == null
                        ? items
                        : items.where((n) => n.kind == _cat.kind).toList();
                    if (list.isEmpty) return _empty();
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _tile(list[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        children: [
          for (final c in _Cat.values) ...[
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: ChoiceChip(
                  label: Text(c.label),
                  selected: _cat == c,
                  onSelected: (_) => setState(() => _cat = c),
                  selectedColor: AppColors.primarySurface,
                  showCheckmark: false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty() => ListView(
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: Column(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedNotificationOff01,
                      size: 40, color: AppColors.textMuted),
                  SizedBox(height: AppSpacing.md),
                  Text('Nothing here yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _tile(AppNotification n) {
    return AppCard(
      onTap: () => _open(n),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: n.read ? AppColors.surfaceAlt : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(n.icon,
                size: 20, color: n.read ? AppColors.textMuted : AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    Text(formatAgo(n.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(n.body,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
