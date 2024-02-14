import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/mem_notifications_page.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/transitions.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/durations.dart';

const keyMemNotificationsView = Key("mem-notifications");

class MemNotificationsView extends ConsumerWidget {
  final int? _memId;

  const MemNotificationsView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemNotificationsView(
          _memId,
          ref.read(memNotificationsByMemIdProvider(_memId)),
        ),
        {
          "_memId": _memId,
        },
      );
}

class _MemNotificationsView extends StatelessWidget {
  final int? _memId;
  final List<MemNotification> _memNotifications;

  const _MemNotificationsView(
    this._memId,
    this._memNotifications,
  ) : super(key: keyMemNotificationsView);

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          final hasEnabledNotifications = _memNotifications
              .where((element) => element.isEnabled())
              .isNotEmpty;
          final text = _memNotifications
              .where((element) => element.isEnabled())
              .map((e) {
            switch (e.type) {
              case MemNotificationType.repeat:
                return l10n.repeated_notification_text(TimeOfDay.fromDateTime(
                  DateAndTime(0, 0, 0, 0, 0, e.time),
                ).format(context));
              case MemNotificationType.afterActStarted:
                return l10n.after_act_started_notification_text(
                    DateFormat(DateFormat.HOUR24_MINUTE)
                        .format(DateAndTime(0, 0, 0, 0, 0, e.time)));
            }
          }).join(", ");

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications,
              color: hasEnabledNotifications ? null : secondaryGreyColor,
            ),
            title: Text(
              hasEnabledNotifications ? text : l10n.no_notifications,
              style: TextStyle(
                color: hasEnabledNotifications ? null : secondaryGreyColor,
              ),
            ),
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
                hasEnabledNotifications ? Icons.edit : Icons.notification_add,
              ),
              tooltip: hasEnabledNotifications
                  ? l10n.edit_notification
                  : l10n.add_notification,
            ),
          );
        },
        {
          "_memId": _memId,
          "_memNotifications": _memNotifications,
        },
      );
}
