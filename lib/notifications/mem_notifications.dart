import 'dart:convert';

import 'package:mem/components/l10n.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem.dart';

import 'channels.dart';
import 'notification/cancel_notification.dart';
import 'notification/notification.dart';
import 'notification/notification_action.dart';
import 'notification/one_time_notification.dart';
import 'notification_ids.dart';

const doneActionId = 'done';
const memIdKey = 'memId';

const _startNotificationBody = 'start';
const _endNotificationBody = 'end';

class MemNotifications {
  final List<Notification> notifications;

  MemNotifications(
    Mem mem,
    int startHourOfDay,
    int startMinuteOfDay,
  ) : notifications = List.empty(growable: true) {
    if (mem.isDone() || mem.isArchived()) {
      notifications.add(CancelNotification(memStartNotificationId(mem.id)));
      notifications.add(CancelNotification(memEndNotificationId(mem.id)));
    } else {
      final now = DateTime.now();

      final periodStart = mem.period?.start;
      if (periodStart != null && periodStart.isAfter(now)) {
        notifications.add(_createNotificationAt(
          memStartNotificationId(mem.id),
          mem.name,
          _startNotificationBody,
          periodStart,
          mem.id,
          startHourOfDay,
          startMinuteOfDay,
        ));
      }

      final periodEnd = mem.period?.end;
      if (periodEnd != null && periodEnd.isAfter(now)) {
        notifications.add(_createNotificationAt(
          memEndNotificationId(mem.id),
          mem.name,
          _endNotificationBody,
          periodEnd,
          mem.id,
          startHourOfDay,
          startMinuteOfDay,
        ));
      }
    }
  }

  Notification _createNotificationAt(
    id,
    title,
    body,
    DateAndTime notifyAt,
    int memId,
    startHourOfDay,
    startMinuteOfDay,
  ) {
    return OneTimeNotification(
      id,
      title,
      body,
      notifyAt.isAllDay == true
          ? DateTime(
              notifyAt.year,
              notifyAt.month,
              notifyAt.day,
              startHourOfDay,
              startMinuteOfDay,
            )
          : notifyAt,
      json.encode({memIdKey: memId}),
      [
        NotificationAction(doneActionId, L10n().doneLabel),
      ],
      reminderChannel,
    );
  }
}
