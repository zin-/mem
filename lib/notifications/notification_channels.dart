import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          l10n.reminderName,
          l10n.reminderDescription,
        ),
        repeatedReminderChannel = NotificationChannel(
          'repeated-reminder',
          l10n.repeatedReminderName,
          l10n.repeatedReminderDescription,
        ),
        activeActNotificationChannel = NotificationChannel(
          'active_act-notification',
          l10n.activeActNotification,
          l10n.activeActNotificationDescription,
          usesChronometer: true,
          ongoing: true,
          autoCancel: false,
        ),
        pausedAct = NotificationChannel(
          "paused_act",
          l10n.pausedActNotification,
          l10n.pausedActNotificationDescription,
          usesChronometer: true,
          autoCancel: false,
        ),
        afterActStartedNotificationChannel = NotificationChannel(
          'after_act_started-notification',
          l10n.afterActStartedNotification,
          l10n.afterActStartedNotificationDescription,
          usesChronometer: true,
          autoCancel: false,
        );
}
