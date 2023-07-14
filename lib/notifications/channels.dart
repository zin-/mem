import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';

import 'notification/channel.dart';

var _initialized = false;

late final NotificationChannel reminderChannel;
late final NotificationChannel repeatedReminderChannel;
late final NotificationChannel activeActNotificationChannel;

void buildNotificationChannels(BuildContext context) => i(
      () {
        if (!_initialized) {
          reminderChannel = NotificationChannel(
            'reminder',
            buildL10n(context).reminder_name,
            buildL10n(context).reminder_description,
          );
          repeatedReminderChannel = NotificationChannel(
            'repeated-reminder',
            buildL10n(context).repeated_reminder_name,
            buildL10n(context).repeated_reminder_description,
          );
          activeActNotificationChannel = NotificationChannel(
            'active_act-notification',
            buildL10n(context).active_act_notification,
            buildL10n(context).active_act_notification_description,
            usesChronometer: true,
            ongoing: true,
          );

          _initialized = true;
        }
      },
      {context, _initialized},
    );
