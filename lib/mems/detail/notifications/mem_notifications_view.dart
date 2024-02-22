import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/transitions.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/durations.dart';

import 'mem_notifications_page.dart';

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
  ) : super(
          key: keyMemNotificationsView,
        );

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          final enables =
              _memNotifications.where((element) => element.isEnabled());

          final hasEnabledNotifications = enables.isNotEmpty;
          final repeat = enables.singleWhereOrNull(
              (element) => element.type == MemNotificationType.repeat);
          final repeatByNDay = enables.singleWhereOrNull(
              (element) => element.type == MemNotificationType.repeatByNDay);
          final afterActStarted = enables.singleWhereOrNull(
              (element) => element.type == MemNotificationType.afterActStarted);

          final text = [
            if (repeat != null)
              if (repeatByNDay != null && (repeatByNDay.time ?? 0) > 1)
                l10n.repeatEveryNDayNotificationText(
                  repeatByNDay.time.toString(),
                  TimeOfDay.fromDateTime(
                    DateAndTime(0, 0, 0, 0, 0, repeat.time),
                  ).format(context),
                )
              else
                l10n.repeatedNotificationText(TimeOfDay.fromDateTime(
                  DateAndTime(0, 0, 0, 0, 0, repeat.time),
                ).format(context)),
            if (afterActStarted != null)
              l10n.afterActStartedNotificationText(
                  DateFormat(DateFormat.HOUR24_MINUTE).format(
                      DateAndTime(0, 0, 0, 0, 0, afterActStarted.time))),
          ].join(", ");

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications,
              color: hasEnabledNotifications ? null : secondaryGreyColor,
            ),
            title: Text(
              hasEnabledNotifications ? text : l10n.noNotifications,
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
                  ? l10n.editNotification
                  : l10n.addNotification,
            ),
          );
        },
        {
          "_memId": _memId,
          "_memNotifications": _memNotifications,
        },
      );
}
