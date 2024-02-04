import 'dart:convert';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/repositories/mem.dart';
import 'client.dart';
import 'notification/cancel_notification.dart';
import 'notification/notification.dart';
import 'notification/one_time_notification.dart';
import 'notification_ids.dart';

const memIdKey = 'memId';

const _startNotificationBody = 'start';
const _endNotificationBody = 'end';

class MemNotifications {
  static List<NotificationV1> of(
    SavedMem mem,
    int hour,
    int minute,
  ) {
    if (mem.isDone || mem.isArchived) {
      return CancelAllMemNotifications.of(mem.id);
    } else {
      final notifications = <NotificationV1>[];
      final now = DateTime.now();

      final periodStart = mem.period?.start;
      if (periodStart != null && periodStart.isAfter(now)) {
        notifications.add(_createNotificationAt(
          memStartNotificationId(mem.id),
          mem.name,
          _startNotificationBody,
          periodStart,
          mem.id,
          hour,
          minute,
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
          hour,
          minute,
        ));
      }

      return notifications;
    }
  }

  static NotificationV1 _createNotificationAt(
    id,
    title,
    body,
    DateAndTime notifyAt,
    int memId,
    int hour,
    int minute,
  ) {
    final notificationClient = NotificationClientV2();

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
              hour,
              minute,
            )
          : notifyAt,
    );
  }
}

class CancelAllMemNotifications {
  static List<NotificationV1> of(int memId) => [
        CancelNotification(memStartNotificationId(memId)),
        CancelNotification(memEndNotificationId(memId)),
        CancelNotification(memRepeatedNotificationId(memId)),
        CancelNotification(activeActNotificationId(memId)),
        CancelNotification(afterActStartedNotificationId(memId)),
      ];
}
