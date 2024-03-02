import 'dart:convert';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification/show_notification.dart';
import 'package:mem/repositories/mem.dart';
import 'client.dart';
import 'notification/cancel_notification.dart';
import 'notification/notification.dart';
import 'notification_ids.dart';

const memIdKey = 'memId';

const _startNotificationBody = 'start';
const _endNotificationBody = 'end';

class MemNotifications {
  static List<ShowNotification> of(
    SavedMem savedMem,
    int hour,
    int minute,
  ) =>
      v(
        () {
          final notifications = <ShowNotification>[];
          final now = DateTime.now();

          final periodStart = savedMem.period?.start;
          if (periodStart != null && periodStart.isAfter(now)) {
            notifications.add(_createNotificationAt(
              memStartNotificationId(savedMem.id),
              savedMem.name,
              _startNotificationBody,
              periodStart,
              savedMem.id,
              hour,
              minute,
            ));
          }

          final periodEnd = savedMem.period?.end;
          if (periodEnd != null && periodEnd.isAfter(now)) {
            notifications.add(_createNotificationAt(
              memEndNotificationId(savedMem.id),
              savedMem.name,
              _endNotificationBody,
              periodEnd,
              savedMem.id,
              hour,
              minute,
            ));
          }

          return notifications;
        },
        {
          "savedMem": savedMem,
          "hour": hour,
          "minute": minute,
        },
      );

  static ShowNotification _createNotificationAt(
    id,
    title,
    body,
    DateAndTime notifyAt,
    int memId,
    int hour,
    int minute,
  ) {
    final notificationClient = NotificationClient();

    return ShowNotification(
      id,
      title,
      body,
      json.encode({memIdKey: memId}),
      [
        notificationClient.notificationActions.doneMemAction,
      ],
      notificationClient.notificationChannels.reminderChannel,
    );
  }
}

class CancelAllMemNotifications {
  static List<Notification> of(int memId) => [
        CancelNotification(memStartNotificationId(memId)),
        CancelNotification(memEndNotificationId(memId)),
        CancelNotification(memRepeatedNotificationId(memId)),
        CancelNotification(activeActNotificationId(memId)),
        CancelNotification(pausedActNotificationId(memId)),
        CancelNotification(afterActStartedNotificationId(memId)),
      ];
}
