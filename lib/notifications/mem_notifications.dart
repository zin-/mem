import 'notification/cancel_notification.dart';
import 'notification/notification.dart';
import 'notification_ids.dart';

const memIdKey = 'memId';

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
