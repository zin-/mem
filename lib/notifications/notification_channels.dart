import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/notifications/notification/action.dart';
import 'package:mem/notifications/notification/done_mem_notification_action.dart';
import 'package:mem/notifications/notification/finish_active_act_notification_action.dart';
import 'package:mem/notifications/notification/pause_act_notification_action.dart';
import 'package:mem/notifications/notification/start_act_notification_action.dart';

import 'notification/channel.dart';

class NotificationChannels {
  late final NotificationChannel reminderChannel;
  late final NotificationChannel repeatedReminderChannel;
  late final NotificationChannel activeActNotificationChannel;
  late final NotificationChannel pausedAct;
  late final NotificationChannel afterActStartedNotificationChannel;

  late final Map<String, NotificationAction> actionMap;

  NotificationChannels(AppLocalizations l10n) {
    final doneMemAction = DoneMemNotificationAction('done-mem', l10n.doneLabel),
        startActAction =
            StartActNotificationAction('start-act', l10n.startLabel),
        finishActiveActAction = FinishActiveActNotificationAction(
          'finish-active_act',
          l10n.finishLabel,
        ),
        pauseAct = PauseActNotificationAction('pause-act', l10n.pauseActLabel);

    actionMap = Map.fromIterable(
      [
        doneMemAction,
        startActAction,
        finishActiveActAction,
        pauseAct,
      ],
      key: (element) => element.id,
    );

    reminderChannel = NotificationChannel(
      'reminder',
      l10n.reminderName,
      l10n.reminderDescription,
      [
        doneMemAction,
        startActAction,
        finishActiveActAction,
      ],
    );
    repeatedReminderChannel = NotificationChannel(
      'repeated-reminder',
      l10n.repeatedReminderName,
      l10n.repeatedReminderDescription,
      [
        startActAction,
        finishActiveActAction,
      ],
    );
    activeActNotificationChannel = NotificationChannel(
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
    );
    pausedAct = NotificationChannel(
      "paused_act",
      l10n.pausedActNotification,
      l10n.pausedActNotificationDescription,
      [
        startActAction,
      ],
      usesChronometer: true,
      autoCancel: false,
    );
    afterActStartedNotificationChannel = NotificationChannel(
      'after_act_started-notification',
      l10n.afterActStartedNotification,
      l10n.afterActStartedNotificationDescription,
      [
        finishActiveActAction,
        pauseAct,
      ],
      usesChronometer: true,
      autoCancel: false,
    );
  }
}
