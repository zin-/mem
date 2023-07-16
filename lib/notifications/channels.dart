import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/actions.dart';
import 'package:mem/notifications/notification/action.dart';

import 'notification/channel.dart';

var _initialized = false;

late final NotificationChannel reminderChannel;
late final NotificationChannel repeatedReminderChannel;
late final NotificationChannel activeActNotificationChannel;

void prepareNotifications([BuildContext? context]) => i(
      () {
        if (!_initialized) {
          final l10n = buildL10n(context);

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

          doneMemAction = NotificationAction(doneMemActionId, l10n.done_label);
          startActAction =
              NotificationAction(startActActionId, l10n.start_label);
          finishActiveActAction =
              NotificationAction(finishActiveActActionId, l10n.finish_label);

          _initialized = true;
        }
      },
      {context, _initialized},
    );
