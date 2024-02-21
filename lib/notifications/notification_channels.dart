import 'package:mem/l10n/app_localizations.dart';

import 'notification/channel.dart';

class NotificationChannels {
  final NotificationChannel reminderChannel;
  final NotificationChannel repeatedReminderChannel;
  final NotificationChannel activeActNotificationChannel;
  final NotificationChannel pausedAct;
  final NotificationChannel afterActStartedNotificationChannel;

  NotificationChannels(AppLocalizations l10n)
      : reminderChannel = NotificationChannel(
          'reminder',
          l10n.reminder_name,
          l10n.reminder_description,
        ),
        repeatedReminderChannel = NotificationChannel(
          'repeated-reminder',
          l10n.repeated_reminder_name,
          l10n.repeated_reminder_description,
        ),
        activeActNotificationChannel = NotificationChannel(
          'active_act-notification',
          l10n.active_act_notification,
          l10n.active_act_notification_description,
          usesChronometer: true,
          ongoing: true,
          autoCancel: false,
        ),
        pausedAct = NotificationChannel(
          "paused_act",
          l10n.paused_act_notification,
          l10n.paused_act_notification_description,
          usesChronometer: true,
          autoCancel: false,
        ),
        afterActStartedNotificationChannel = NotificationChannel(
          'after_act_started-notification',
          l10n.after_act_started_notification,
          l10n.after_act_started_notification_description,
          usesChronometer: true,
          autoCancel: false,
        );
}
