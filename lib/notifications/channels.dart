import 'package:flutter/material.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';

import 'actions.dart';
import 'notification/action.dart';
import 'notification/channel.dart';

var _initialized = false;

late final NotificationChannel reminderChannel;
late final NotificationChannel repeatedReminderChannel;
late final NotificationChannel activeActNotificationChannel;
late final NotificationChannel afterActStartedNotificationChannel;

// TODO repository（かな？service？）の初期化のタイミングでこれも初期化したい
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
          afterActStartedNotificationChannel = NotificationChannel(
            'after_act_started-notification',
            l10n.after_act_started_notification,
            l10n.after_act_started_notification_description,
            usesChronometer: true,
            autoCancel: false,
          );

          doneMemAction = NotificationAction(
            doneMemActionId,
            l10n.done_label,
            (memId) async {
              await MemService().doneByMemId(memId);
            },
          );
          startActAction = NotificationAction(
            startActActionId,
            l10n.start_label,
            (memId) async {
              await ActService().startBy(memId);
            },
          );
          finishActiveActAction = NotificationAction(
            finishActiveActActionId,
            l10n.finish_label,
            (memId) async {
              final acts = (await ActRepository().shipByMemId(memId));

              await ActService().finish(
                acts.isEmpty ? await ActService().startBy(memId) : acts.last,
              );
            },
          );

          _initialized = true;
        }
      },
      {context, _initialized},
    );
