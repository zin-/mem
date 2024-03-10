import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/notifications/notification/action.dart';
import 'package:mem/notifications/notification/done_mem_notification_action.dart';
import 'package:mem/notifications/notification/finish_active_act_notification_action.dart';
import 'package:mem/notifications/notification/pause_act_notification_action.dart';
import 'package:mem/notifications/notification/start_act_notification_action.dart';
import 'package:mem/notifications/notification/type.dart';

import 'notification/channel.dart';

class NotificationChannels {
  late final Map<NotificationType, NotificationChannel> notificationChannels;
  late final Map<String, NotificationAction> actionMap;

  NotificationChannels(AppLocalizations l10n) {
    final doneMemAction = DoneMemNotificationAction(l10n.doneLabel),
        startActAction = StartActNotificationAction(l10n.startLabel),
        finishActiveActAction =
            FinishActiveActNotificationAction(l10n.finishLabel),
        pauseAct = PauseActNotificationAction(l10n.pauseActLabel);

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
