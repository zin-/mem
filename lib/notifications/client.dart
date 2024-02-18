import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/action.dart';
import 'package:mem/notifications/notification/channel.dart';
import 'package:mem/notifications/notification/done_mem_notification_action.dart';
import 'package:mem/notifications/notification/finish_active_act_notification_action.dart';
import 'package:mem/notifications/notification/pause_act_notification_action.dart';
import 'package:mem/notifications/notification/repeated_notification.dart';
import 'package:mem/notifications/notification/start_act_notification_action.dart';
import 'package:mem/notifications/notification_channels.dart';
import 'package:mem/notifications/notification_ids.dart';

import 'notification_actions.dart';
import 'notification_repository.dart';

// TODO refactor
class NotificationClientV3 {
  final NotificationChannels _notificationChannels;
  final NotificationActions _notificationActions;

  final NotificationRepository _notificationRepository;

  registerMemRepeatNotification(
    String memName,
    MemNotification repeatMemNotification,
    MemNotification? repeatEveryNDay,
  ) =>
      d(
        () async {
          final now = DateTime.now();
          final hours = (repeatMemNotification.time! / 60 / 60).floor();
          final minutes =
              ((repeatMemNotification.time! - hours * 60 * 60) / 60).floor();
          final seconds =
              ((repeatMemNotification.time! - ((hours * 60) + minutes) * 60) /
                      60)
                  .floor();
          var notifyFirstAt = DateTime(
            now.year,
            now.month,
            now.day,
            hours,
            minutes,
            seconds,
          );
          if (notifyFirstAt.isBefore(now)) {
            notifyFirstAt = notifyFirstAt.add(const Duration(days: 1));
          }

          final memRepeatNotification = RepeatedNotification(
            memRepeatedNotificationId(repeatMemNotification.memId!),
            memName,
            repeatMemNotification.message,
            json.encode({memIdKey: repeatMemNotification.memId}),
            [
              _notificationActions.startActAction,
              _notificationActions.finishActiveActAction,
            ],
            _notificationChannels.repeatedReminderChannel,
            notifyFirstAt,
            NotificationInterval.perDay,
          );
          await _notificationRepository.receive(memRepeatNotification);
        },
        {
          "memName": memName,
          "repeatMemNotification": repeatMemNotification,
        },
      );

  NotificationClientV3._(
    this._notificationChannels,
    this._notificationActions,
    this._notificationRepository,
  );

  static NotificationClientV3? _instance;

  factory NotificationClientV3([BuildContext? context]) {
    final l10n = buildL10n(context);
    return _instance ??= NotificationClientV3._(
      NotificationChannels(l10n),
      NotificationActions(l10n),
      NotificationRepository(),
    );
  }
}

class NotificationClientV2 {
  late final NotificationChannel reminderChannel;
  late final NotificationChannel repeatedReminderChannel;
  late final NotificationChannel activeActNotificationChannel;
  late final NotificationChannel pausedAct;
  late final NotificationChannel afterActStartedNotificationChannel;

  late final NotificationAction doneMemAction;
  late final NotificationAction startActAction;
  late final NotificationAction finishActiveActAction;
  late final NotificationAction pauseAct;

  final notificationActions = <NotificationAction>[];

  NotificationClientV2._(AppLocalizations l10n) {
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
    pausedAct = NotificationChannel(
      "paused_act",
      l10n.paused_act_notification,
      l10n.paused_act_notification_description,
      usesChronometer: true,
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

  static NotificationClientV2? _instance;

  factory NotificationClientV2([BuildContext? context]) => v(
        () => _instance ??= NotificationClientV2._(buildL10n(context)),
        context,
      );
}
