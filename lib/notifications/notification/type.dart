// FIXME 通知種別としては、NotificationChannelとほぼ同じ概念なのでは？
//  微妙に異なる
//    NotificationChannelではその挙動について定義される
//      具体的にはstartMemとendMemは同じChannel
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_ids.dart';

enum NotificationType {
  startMem,
  endMem,
  repeat,
  activeAct,
  pausedAct,
  afterActStarted,
}

extension NotificationChannelBuilder on NotificationType {
  int buildNotificationId(int memId) => v(
        () {
          switch (this) {
            case NotificationType.startMem:
              return memStartNotificationId(memId);
            case NotificationType.endMem:
              return memEndNotificationId(memId);
            case NotificationType.repeat:
              return memRepeatedNotificationId(memId);
            case NotificationType.activeAct:
              return activeActNotificationId(memId);
            case NotificationType.pausedAct:
              return pausedActNotificationId(memId);
            case NotificationType.afterActStarted:
              return afterActStartedNotificationId(memId);
          }
        },
        {
          'this': this,
          'memId': memId,
        },
      );
}
