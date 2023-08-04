import 'dart:convert';

import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/time_of_day.dart';
import 'package:mem/core/mem.dart';

import 'client.dart';
import 'notification/cancel_notification.dart';
import 'notification/notification.dart';
import 'notification/one_time_notification.dart';
import 'notification_ids.dart';

const memIdKey = 'memId';

const _startNotificationBody = 'start';
const _endNotificationBody = 'end';

class MemNotifications {
  static List<Notification> of(
    Mem mem,
    TimeOfDay startOfDay,
  ) {
    if (mem.isDone() || mem.isArchived()) {
      return CancelAllMemNotifications.of(mem.id);
    } else {
      final notifications = <Notification>[];
      final now = DateTime.now();

      final periodStart = mem.period?.start;
      if (periodStart != null && periodStart.isAfter(now)) {
        notifications.add(_createNotificationAt(
          memStartNotificationId(mem.id),
          mem.name,
          _startNotificationBody,
          periodStart,
          mem.id,
          startOfDay,
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
          startOfDay,
        ));
      }

      return notifications;
    }
  }

  static Notification _createNotificationAt(
    id,
    title,
    body,
    DateAndTime notifyAt,
    int memId,
    TimeOfDay startOfDay,
  ) {
    final notificationClient = NotificationClient();

    return OneTimeNotification(
      id,
      title,
      body,
      json.encode({memIdKey: memId}),
      [
        notificationClient.doneMemAction,
      ],
      notificationClient.reminderChannel,
      notifyAt.isAllDay == true
          ? DateTime(
              notifyAt.year,
              notifyAt.month,
              notifyAt.day,
              startOfDay.hour,
              startOfDay.minute,
            )
          : notifyAt,
    );
  }
}

class CancelAllMemNotifications {
  static List<Notification> of(int memId) => [
        CancelNotification(memStartNotificationId(memId)),
        CancelNotification(memEndNotificationId(memId)),
        CancelNotification(memRepeatedNotificationId(memId)),
        CancelNotification(activeActNotificationId(memId)),
        CancelNotification(afterActStartedNotificationId(memId)),
      ];
}
