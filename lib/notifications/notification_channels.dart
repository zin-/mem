import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

import 'notification/action.dart';
import 'notification/notification.dart';
import 'notification/type.dart';

const pauseActNotificationBody = "Paused";

class NotificationChannels {
  final AppLocalizations _l10n;

  late final Map<String, NotificationAction> actionMap;

  Future<Notification> buildNotification(
    NotificationType notificationType,
    int memId,
  ) =>
      v(
        () async {
          final title = (await MemRepositoryV1().shipById(memId)).name;
          String body;
          switch (notificationType) {
            case NotificationType.startMem:
              body = "start";
              break;
            case NotificationType.endMem:
              body = "end";
              break;
            case NotificationType.repeat:
              body = ((await MemNotificationRepository().shipByMemId(memId)))
                      .singleWhereOrNull((element) => element.isRepeated())
                      ?.message ??
                  "Repeat";
              break;
            case NotificationType.afterActStarted:
              body = ((await MemNotificationRepository().shipByMemId(memId)))
                  .singleWhere((element) => element.isAfterActStarted())
                  .message;
              break;
            case NotificationType.activeAct:
              body = "Running";
              break;
            case NotificationType.pausedAct:
              body = pauseActNotificationBody;
              break;
          }

          return Notification(
            notificationType.buildNotificationId(memId),
            title,
            body,
            notificationType.buildNotificationChannel(_l10n),
            {memIdKey: memId},
          );
        },
        {
          "notificationType": notificationType,
          "memId": memId,
        },
      );

  NotificationChannels(this._l10n);
}
