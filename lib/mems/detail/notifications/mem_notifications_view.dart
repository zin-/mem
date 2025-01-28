import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_text.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/transitions.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/durations.dart';

import 'mem_notifications_page.dart';

const keyMemNotificationsView = Key('mem-notifications');

class MemNotificationsView extends ConsumerWidget {
  final int? _memId;

  const MemNotificationsView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemNotificationsView(
          _memId,
          ref
              .watch(memNotificationsByMemIdProvider(_memId))
              .map((e) => e.value),
        ),
        {
          '_memId': _memId,
        },
      );
}

class _MemNotificationsView extends StatelessWidget {
  final int? _memId;
  final Iterable<MemNotification> _memNotifications;

  const _MemNotificationsView(
    this._memId,
    this._memNotifications,
  ) : super(
          key: keyMemNotificationsView,
        );

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          final enables = _memNotifications.where((e) => e.isEnabled());

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications,
              color: enables.isEmpty ? secondaryGreyColor : null,
            ),
            title: MemNotificationText(_memId),
            trailing: IconButton(
              onPressed: () => v(
                () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        MemNotificationsPage(_memId),
                    transitionsBuilder: detailTransitionsBuilder,
                    transitionDuration: defaultTransitionDuration,
                    reverseTransitionDuration: defaultTransitionDuration,
                  ),
                ),
              ),
              icon: Icon(
                enables.isEmpty ? Icons.notification_add : Icons.edit,
              ),
              tooltip: enables.isEmpty
                  ? l10n.addNotification
                  : l10n.editNotification,
            ),
          );
        },
        {
          '_memId': _memId,
          '_memNotifications': _memNotifications,
        },
      );
}
