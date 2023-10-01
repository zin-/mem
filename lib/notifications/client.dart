import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification/action.dart';
import 'package:mem/notifications/notification/channel.dart';
import 'package:mem/notifications/notification/done_mem_notification_action.dart';
import 'package:mem/notifications/notification/finish_active_act_notification_action.dart';
import 'package:mem/notifications/notification/pause_act_notification_action.dart';
import 'package:mem/notifications/notification/start_act_notification_action.dart';

class NotificationClient {
  late final NotificationChannel reminderChannel;
  late final NotificationChannel repeatedReminderChannel;
  late final NotificationChannel activeActNotificationChannel;
  late final NotificationChannel afterActStartedNotificationChannel;

  late final NotificationAction doneMemAction;
  late final NotificationAction startActAction;
  late final NotificationAction finishActiveActAction;
  late final NotificationAction pauseAct;

  final notificationActions = <NotificationAction>[];

  NotificationClient._(AppLocalizations l10n) {
    reminderChannel = NotificationChannel(
      'reminder',
      l10n.reminder_name,
      l10n.reminder_description,
    );
    repeatedReminderChannel = NotificationChannel(
      'repeated-reminder',
      l10n.repeated_reminder_name,
      l10n.repeated_reminder_description,
    );
    activeActNotificationChannel = NotificationChannel(
      'active_act-notification',
      l10n.active_act_notification,
      l10n.active_act_notification_description,
      usesChronometer: true,
      ongoing: true,
      autoCancel: false,
    );
    afterActStartedNotificationChannel = NotificationChannel(
      'after_act_started-notification',
      l10n.after_act_started_notification,
      l10n.after_act_started_notification_description,
      usesChronometer: true,
      autoCancel: false,
    );

    notificationActions.addAll([
      doneMemAction = DoneMemNotificationAction('done-mem', l10n.done_label),
      startActAction =
          StartActNotificationAction('start-act', l10n.start_label),
      finishActiveActAction = FinishActiveActNotificationAction(
        'finish-active_act',
        l10n.finish_label,
      ),
      pauseAct = PauseActNotificationAction('pause-act', l10n.pause_act_label),
    ]);
  }

  static NotificationClient? _instance;

  factory NotificationClient([BuildContext? context]) => i(
        () => _instance ??= NotificationClient._(buildL10n(context)),
        context,
      );
}
