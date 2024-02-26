import 'dart:convert';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem.dart';
import 'client.dart';
import 'mem_notifications.dart';
import 'notification/cancel_notification.dart';
import 'notification/repeated_notification.dart';
import 'notification_ids.dart';
import 'notification_repository.dart';

class NotificationService {
  final NotificationRepository _notificationRepository;

  // FIXME ここにあるのはおかしい
  final NotificationClientV2 _notificationClient;

  Future<void> memReminder(SavedMem mem) => v(
        () async {
          final memNotifications = MemNotifications.of(
            mem,
            // TODO 時間がないときのデフォルト値を設定から取得する
            5, 0,
          );

          for (var element in memNotifications) {
            await _notificationRepository.receive(element);
          }
        },
        mem,
      );

  Future<void> memRepeatedReminder(
    SavedMem mem,
    MemNotification? memNotification,
  ) =>
      v(
        () async {
          if (memNotification == null) {
            await _notificationRepository.receive(
              CancelNotification(memRepeatedNotificationId(mem.id)),
            );
          } else {
            final now = DateTime.now();
            final hours = (memNotification.time! / 60 / 60).floor();
            final minutes =
                ((memNotification.time! - hours * 60 * 60) / 60).floor();
            final seconds =
                ((memNotification.time! - ((hours * 60) + minutes) * 60) / 60)
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

            final repeatedNotification = RepeatedNotification(
              memRepeatedNotificationId(mem.id),
              mem.name,
              memNotification.message,
              json.encode({memIdKey: memNotification.memId}),
              [
                _notificationClient.startActAction,
                _notificationClient.finishActiveActAction,
              ],
              _notificationClient.repeatedReminderChannel,
              notifyFirstAt,
              NotificationInterval.perDay,
            );

            await _notificationRepository.receive(repeatedNotification);
          }
        },
        {mem, memNotification},
      );

  NotificationService._(this._notificationRepository, this._notificationClient);

  static NotificationService? _instance;

  factory NotificationService() => i(
        () => _instance ??= NotificationService._(
          NotificationRepository(),
          NotificationClientV2(),
        ),
      );
}
