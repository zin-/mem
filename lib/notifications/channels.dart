import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';

import 'notification/channel.dart';

late final NotificationChannel reminderChannel;
late final NotificationChannel repeatedReminderChannel;
late final NotificationChannel activeActNotificationChannel;

var _initialized = false;

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
            'active-act-notification',
            // TODO l10n
            buildL10n(context).repeated_reminder_name,
            // TODO l10n
            buildL10n(context).repeated_reminder_description,
          );

          _initialized = true;
        }
      },
      {context, _initialized},
    );
