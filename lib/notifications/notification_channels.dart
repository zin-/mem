import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/acts/client.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

import 'notification/action.dart';
import 'notification/channel.dart';
import 'notification/notification.dart';
import 'notification/type.dart';

const doneMemNotificationActionId = "done-mem";
const startActNotificationActionId = "start-act";
const finishActiveActNotificationActionId = "finish-active_act";
const pauseActNotificationActionId = "pause-act";
const pauseActNotificationBody = "Paused";

class NotificationChannels {
  late final Map<NotificationType, NotificationChannel> notificationChannels;
  late final Map<String, NotificationAction> actionMap;

  Future<Notification> buildNotification(
    NotificationType notificationType,
    int memId,
  ) =>
      v(
        () async {
          final title = (await MemRepository().shipById(memId)).name;
          int id;
          String body;
          switch (notificationType) {
            case NotificationType.startMem:
              id = memStartNotificationId(memId);
              body = "start";
              break;
            case NotificationType.endMem:
              id = memEndNotificationId(memId);
              body = "end";
              break;
            case NotificationType.repeat:
              id = memRepeatedNotificationId(memId);
              body = ((await MemNotificationRepository().shipByMemId(memId)))
                      .singleWhereOrNull((element) => element.isRepeated())
                      ?.message ??
                  "Repeat";
              break;
            case NotificationType.afterActStarted:
              id = afterActStartedNotificationId(memId);
              body = ((await MemNotificationRepository().shipByMemId(memId)))
                  .singleWhere((element) => element.isAfterActStarted())
                  .message;
              break;
            case NotificationType.activeAct:
              id = activeActNotificationId(memId);
              body = "Running";
              break;
            case NotificationType.pausedAct:
              id = pausedActNotificationId(memId);
              body = pauseActNotificationBody;
              break;
          }
          final channel = notificationChannels[notificationType]!;

          return Notification(
            id,
            title,
            body,
            channel,
            {memIdKey: memId},
          );
        },
        {
          "notificationType": notificationType,
          "memId": memId,
        },
      );

  NotificationChannels(AppLocalizations l10n) {
    final doneMemAction = NotificationAction(
          doneMemNotificationActionId,
          l10n.doneLabel,
          (memId) => v(
            () => MemService().doneByMemId(memId),
            {"memId": memId},
          ),
        ),
        startActAction = NotificationAction(
          startActNotificationActionId,
          l10n.startLabel,
          (memId) => v(
            () => ActsClient().start(memId, DateAndTime.now()),
            {"memId": memId},
          ),
        ),
        finishActiveActAction = NotificationAction(
          finishActiveActNotificationActionId,
          l10n.finishLabel,
          (memId) => v(
            () async => await ActsClient().finish(
              memId,
              DateAndTime.now(),
            ),
            {"memId": memId},
          ),
        ),
        pauseAct = NotificationAction(
          pauseActNotificationActionId,
          l10n.pauseActLabel,
          (memId) => v(
            () async => await ActsClient().pause(
              memId,
              DateAndTime.now(),
            ),
            {"memId": memId},
          ),
        );

    actionMap = Map.fromIterable(
      [
        doneMemAction,
        startActAction,
        finishActiveActAction,
        pauseAct,
      ],
      key: (element) => element.id,
    );

    final reminderChannel = NotificationChannel(
      "reminder",
      l10n.reminderName,
      l10n.reminderDescription,
      [
        doneMemAction,
        startActAction,
        finishActiveActAction,
      ],
    );

    notificationChannels = {
      NotificationType.startMem: reminderChannel,
      NotificationType.endMem: reminderChannel,
      NotificationType.repeat: NotificationChannel(
        "repeated-reminder",
        l10n.repeatedReminderName,
        l10n.repeatedReminderDescription,
        [
          startActAction,
          finishActiveActAction,
        ],
      ),
      NotificationType.activeAct: NotificationChannel(
        'active_act-notification',
        l10n.activeActNotification,
        l10n.activeActNotificationDescription,
        [
          finishActiveActAction,
          pauseAct,
        ],
        usesChronometer: true,
        ongoing: true,
        autoCancel: false,
      ),
      NotificationType.pausedAct: NotificationChannel(
        "paused_act",
        l10n.pausedActNotification,
        l10n.pausedActNotificationDescription,
        [
          startActAction,
        ],
        usesChronometer: true,
        autoCancel: false,
      ),
      NotificationType.afterActStarted: NotificationChannel(
        'after_act_started-notification',
        l10n.afterActStartedNotification,
        l10n.afterActStartedNotificationDescription,
        [
          finishActiveActAction,
          pauseAct,
        ],
        usesChronometer: true,
        autoCancel: false,
      ),
    };
  }
}
