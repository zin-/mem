import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/mems/mem_notification_repository.dart';
import 'package:mem/mems/mem_repository.dart';

import 'notification/action.dart';
import 'notification/notification.dart';
import 'notification/type.dart';

const pauseActNotificationBody = "Paused";

class NotificationChannels {
  final AppLocalizations _l10n;

  late final Map<String, NotificationAction> actionMap;

  Future<Notification> buildNotification(
    NotificationType notificationType,
    int? memId,
  ) =>
      v(
        () async {
          String title;
          if (memId == null) {
            title = "Want to do something?";
          } else {
            title = await MemRepositoryV2()
                .ship(id: memId)
                .then((value) => value.single.value.name);
          }

          String body;
          switch (notificationType) {
            case NotificationType.startMem:
              body = "start";
              break;
            case NotificationType.endMem:
              body = "end";
              break;
            case NotificationType.repeat:
              body = ((await MemNotificationRepositoryV2().ship(memId: memId)))
                      .singleWhereOrNull(
                          (element) => element.value.isRepeated())
                      ?.value
                      .message ??
                  "Repeat";
              break;
            case NotificationType.afterActStarted:
              body = ((await MemNotificationRepositoryV2().ship(memId: memId)))
                  .singleWhere((element) => element.value.isAfterActStarted())
                  .value
                  .message;
              break;
            case NotificationType.activeAct:
              body = "Running";
              break;
            case NotificationType.pausedAct:
              body = pauseActNotificationBody;
              break;
            case NotificationType.notifyAfterInactivity:
              body = "The specified time has passed without any activity.";
          }

          return Notification(
            notificationType.buildNotificationId(memId),
            title,
            body,
            notificationType.buildNotificationChannel(_l10n),
            {
              if (memId != null) memIdKey: memId,
            },
          );
        },
        {
          'notificationType': notificationType,
          'memId': memId,
        },
      );

  NotificationChannels(this._l10n);
}
