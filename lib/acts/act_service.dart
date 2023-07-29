import 'dart:convert';

import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_notification_repository.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/one_time_notification.dart';
import 'package:mem/notifications/notification/show_notification.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/notification_repository.dart';

class ActService {
  final ActRepository _actRepository;
  final MemRepository _memRepository;
  final MemNotificationRepository _memNotificationRepository;
  final NotificationRepository _notificationRepository;

  // FIXME ここに定義されるのはおかしい
  final NotificationClient _notificationClient;

  Future<Act> startBy(int memId) => i(
        () async {
          final received = await _actRepository.receive(
            Act(
              memId,
              DateAndTimePeriod.startNow(),
            ),
          );

          final mem = await _memRepository.shipById(memId);

          await _notificationRepository.receive(
            ShowNotification(
              activeActNotificationId(memId),
              mem.name,
              'Running',
              json.encode({memIdKey: memId}),
              [
                _notificationClient.finishActiveActAction,
              ],
              _notificationClient.activeActNotificationChannel,
            ),
          );

          final afterActStartedNotifications = await _memNotificationRepository
              .shipByMemIdAndAfterActStarted(memId);

          if (afterActStartedNotifications.isNotEmpty) {
            for (var notification in afterActStartedNotifications) {
              await _notificationRepository.receive(
                OneTimeNotification(
                  afterActStartedNotificationId(memId),
                  mem.name,
                  notification.message,
                  json.encode({memIdKey: memId}),
                  [
                    _notificationClient.finishActiveActAction,
                  ],
                  _notificationClient.afterActStartedNotificationChannel,
                  DateTime.now().add(Duration(seconds: notification.time!)),
                ),
              );
            }
          }

          return received;
        },
        memId,
      );

  Future<Act> finish(Act act) => i(
        () async {
          final finished = await _actRepository.replace(
            Act(
              act.memId,
              DateAndTimePeriod(
                start: act.period.start,
                end: DateAndTime.now(),
              ),
              id: act.id,
            ),
          );

          await _notificationRepository
              .discard(activeActNotificationId(act.memId));
          await _notificationRepository
              .discard(afterActStartedNotificationId(act.memId));

          // ISSUE #226

          return finished;
        },
        act,
      );

  ActService._(
    this._actRepository,
    this._memRepository,
    this._memNotificationRepository,
    this._notificationRepository,
    this._notificationClient,
  );

  static ActService? _instance;

  factory ActService() => _instance ??= _instance = ActService._(
        ActRepository(),
        MemRepository(),
        MemNotificationRepository(),
        NotificationRepository(),
        NotificationClient(),
      );
}
