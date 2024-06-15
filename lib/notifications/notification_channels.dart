import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/acts/client.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/notifications/mem_notifications.dart';
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
  final AppLocalizations _l10n;

  late final Map<NotificationType, NotificationChannel> notificationChannels;
  late final Map<String, NotificationAction> actionMap;

  Future<Notification> buildNotification(
    NotificationType notificationType,
    int memId,
  ) =>
      v(
        () async {
          final title = (await MemRepository().shipById(memId)).name;
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
          final channel = notificationChannels[notificationType]!;

          return Notification(
            notificationType.buildNotificationId(memId),
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

  NotificationChannels(this._l10n) {
    final doneMemAction = NotificationAction(
          doneMemNotificationActionId,
          _l10n.doneLabel,
          (memId) => v(
            () => MemService().doneByMemId(memId),
            {"memId": memId},
          ),
        ),
        startActAction = NotificationAction(
          startActNotificationActionId,
          _l10n.startLabel,
          (memId) => v(
            () => ActsClient().start(memId, DateAndTime.now()),
            {"memId": memId},
          ),
        ),
        finishActiveActAction = NotificationAction(
          finishActiveActNotificationActionId,
          _l10n.finishLabel,
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
          _l10n.pauseActLabel,
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
      _l10n.reminderName,
      _l10n.reminderDescription,
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
        _l10n.repeatedReminderName,
        _l10n.repeatedReminderDescription,
        [
          startActAction,
          finishActiveActAction,
        ],
      ),
      NotificationType.activeAct: NotificationChannel(
        'active_act-notification',
        _l10n.activeActNotification,
        _l10n.activeActNotificationDescription,
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
        _l10n.pausedActNotification,
        _l10n.pausedActNotificationDescription,
        [
          startActAction,
        ],
        usesChronometer: true,
        autoCancel: false,
      ),
      NotificationType.afterActStarted: NotificationChannel(
        'after_act_started-notification',
        _l10n.afterActStartedNotification,
        _l10n.afterActStartedNotificationDescription,
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
