import 'dart:convert';

import 'package:mem/core/date_and_time/time_of_day.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';

import 'actions.dart';
import 'channels.dart';
import 'mem_notifications.dart';
import 'notification/cancel_notification.dart';
import 'notification/repeated_notification.dart';
import 'notification_ids.dart';
import 'notification_repository.dart';

class NotificationService {
  final NotificationRepository _notificationRepository;

  Future<void> memReminder(Mem mem) => i(
        () async {
          // TODO 時間がないときのデフォルト値を設定から取得する
          final memNotifications = MemNotifications(mem, 5, 0);

          for (var element in memNotifications.notifications) {
            await _notificationRepository.receive(element);
          }
        },
        mem,
      );

  Future<void> memRepeatedReminder(
    Mem mem,
    MemNotification? memNotification,
  ) =>
      i(
        () async {
          if (memNotification == null) {
            await _notificationRepository.receive(
              CancelNotification(memRepeatedNotificationId(mem.id)),
            );
          } else {
            final now = DateTime.now();
            final timeOfDay = TimeOfDay.fromSeconds(memNotification.time!);
            var notifyFirstAt = DateTime(
              now.year,
              now.month,
              now.day,
              timeOfDay.hour,
              timeOfDay.minute,
              timeOfDay.second,
            );
            if (notifyFirstAt.isBefore(now)) {
              notifyFirstAt = notifyFirstAt.add(const Duration(days: 1));
            }

            final repeatedNotification = RepeatedNotification(
              memRepeatedNotificationId(mem.id),
              mem.name,
              memNotification.message,
              json.encode({'memId': memNotification.memId}),
              [
                startActAction,
                finishActiveActAction,
              ],
              repeatedReminderChannel,
              notifyFirstAt,
              NotificationInterval.perDay,
            );

            await _notificationRepository.receive(repeatedNotification);
          }
        },
        {mem, memNotification},
      );

  NotificationService._(this._notificationRepository);

  static NotificationService? _instance;

  factory NotificationService() =>
      _instance ??= _instance = NotificationService._(
        NotificationRepository(),
      );
}
