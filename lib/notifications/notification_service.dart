import 'dart:convert';

import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_repeated_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/notifications/actions.dart';

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
    MemRepeatedNotification? memRepeatedNotification,
  ) =>
      i(
        () async {
          if (memRepeatedNotification == null) {
            await _notificationRepository.receive(
              CancelNotification(memRepeatedNotificationId(mem.id)),
            );
          } else {
            final now = DateTime.now();
            var notifyFirstAt = DateTime(
              now.year,
              now.month,
              now.day,
              memRepeatedNotification.timeOfDay.hour,
              memRepeatedNotification.timeOfDay.minute,
              memRepeatedNotification.timeOfDay.second,
            );
            if (notifyFirstAt.isBefore(now)) {
              notifyFirstAt = notifyFirstAt.add(const Duration(days: 1));
            }

            final repeatedNotification = RepeatedNotification(
              memRepeatedNotificationId(mem.id),
              mem.name,
              'Repeat',
              json.encode({'memId': memRepeatedNotification.memId}),
              [
                startActAction,
              ],
              repeatedReminderChannel,
              notifyFirstAt,
              NotificationInterval.perDay,
            );

            await _notificationRepository.receive(repeatedNotification);
          }
        },
        {mem, memRepeatedNotification},
      );

  NotificationService._(this._notificationRepository);

  static NotificationService? _instance;

  factory NotificationService({
    NotificationRepository? notificationRepository,
  }) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = NotificationService._(
        notificationRepository ?? NotificationRepository(),
      );
      _instance = tmp;
    }
    return tmp;
  }
}

// ISSUE #225
// coverage:ignore-start
Future<void> notificationActionHandler(
  int notificationId,
  String actionId,
  String? input,
  Map<dynamic, dynamic> payload,
) =>
    v(
      () async {
        if (actionId == doneMemActionId) {
          if (payload.containsKey(memIdKey)) {
            final memId = payload[memIdKey];
            if (memId is int) {
              await MemService().doneByMemId(memId);
            }
          }
        } else if (actionId == startActActionId) {
          final memId = payload[memIdKey];
          if (memId is int) {
            await ActService().startBy(memId);
          }
        } else if (actionId == finishActiveActActionId) {
          final memId = payload[memIdKey];
          if (memId is int) {
            final act = (await ActRepository().shipActive())
                .lastWhere((element) => element.memId == memId);
            await ActService().finish(act);
          }
        }
      },
      {
        'id': notificationId,
        'actionId': actionId,
        'input': input,
        'payload': payload
      },
    );
// coverage:ignore-end
