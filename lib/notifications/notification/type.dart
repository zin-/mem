import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_actions.dart';
import 'package:mem/notifications/notification_ids.dart';

import 'channel.dart';

// FIXME 通知種別としては、NotificationChannelとほぼ同じ概念なのでは？
//  微妙に異なる
//    NotificationChannelではその挙動について定義される
//      具体的にはstartMemとendMemは同じChannel
enum NotificationType {
  startMem,
  endMem,
  repeat,
  activeAct,
  pausedAct,
  afterActStarted,
  notifyAfterInactivity,
}

extension NotificationChannelBuilder on NotificationType {
  int buildNotificationId([int? memId]) => v(
        () {
          switch (this) {
            case NotificationType.startMem:
              return memStartNotificationId(memId!);
            case NotificationType.endMem:
              return memEndNotificationId(memId!);
            case NotificationType.repeat:
              return memRepeatedNotificationId(memId!);
            case NotificationType.activeAct:
              return activeActNotificationId(memId!);
            case NotificationType.pausedAct:
              return pausedActNotificationId(memId!);
            case NotificationType.afterActStarted:
              return afterActStartedNotificationId(memId!);
            case NotificationType.notifyAfterInactivity:
              return notifyAfterInactivityNotificationId();
          }
        },
        {
          'this': this,
          'memId': memId,
        },
      );

  NotificationChannel buildNotificationChannel([AppLocalizations? l10n]) => v(
        () {
          final notificationActionMap =
              Map.fromEntries(buildNotificationActions(l10n).map(
            (e) => MapEntry(e.id, e),
          ));

          final reminderChannel = NotificationChannel(
            reminderNotificationChannelId,
            l10n?.reminderName ?? "",
            l10n?.reminderDescription ?? "",
            [
              notificationActionMap[doneMemNotificationActionId]!,
              notificationActionMap[startActNotificationActionId]!,
              notificationActionMap[finishActiveActNotificationActionId]!,
            ],
          );

          switch (this) {
            case NotificationType.startMem:
              return reminderChannel;
            case NotificationType.endMem:
              return reminderChannel;
            case NotificationType.repeat:
              return NotificationChannel(
                repeatReminderNotificationChannelId,
                l10n?.repeatedReminderName ?? "",
                l10n?.repeatedReminderDescription ?? "",
                [
                  notificationActionMap[startActNotificationActionId]!,
                  notificationActionMap[finishActiveActNotificationActionId]!,
                ],
              );
            case NotificationType.activeAct:
              return NotificationChannel(
                activeActNotificationChannelId,
                l10n?.activeActNotification ?? "",
                l10n?.activeActNotificationDescription ?? "",
                [
                  notificationActionMap[finishActiveActNotificationActionId]!,
                  notificationActionMap[pauseActNotificationActionId]!,
                ],
                usesChronometer: true,
                ongoing: true,
                autoCancel: false,
                playSound: false,
                enableVibration: false,
              );
            case NotificationType.pausedAct:
              return NotificationChannel(
                pausedActNotificationChannelId,
                l10n?.pausedActNotification ?? "",
                l10n?.pausedActNotificationDescription ?? "",
                [
                  notificationActionMap[startActNotificationActionId]!,
                ],
                usesChronometer: true,
                autoCancel: false,
                playSound: false,
                enableVibration: false,
              );
            case NotificationType.afterActStarted:
              return NotificationChannel(
                afterActStartedNotificationChannelId,
                l10n?.afterActStartedNotification ?? "",
                l10n?.afterActStartedNotificationDescription ?? "",
                [
                  notificationActionMap[finishActiveActNotificationActionId]!,
                  notificationActionMap[pauseActNotificationActionId]!,
                ],
                usesChronometer: true,
                autoCancel: false,
              );
            case NotificationType.notifyAfterInactivity:
              return NotificationChannel(
                notifyAfterInactivityNotificationChannelId,
                l10n?.notifyAfterInactivityNotification ?? "",
                l10n?.notifyAfterInactivityNotificationDescription ?? "",
                [],
                usesChronometer: true,
                autoCancel: false,
              );
          }
        },
        {
          'this': this,
          'l10n': l10n,
        },
      );
}
