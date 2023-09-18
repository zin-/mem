import 'dart:convert';

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

import 'act_repository.dart';

class ActService {
  final ActRepository _actRepository;
  final MemRepository _memRepository;
  final MemNotificationRepository _memNotificationRepository;
  final NotificationRepository _notificationRepository;

  // FIXME ここに定義されるのはおかしい
  final NotificationClient _notificationClient;

  Future<Act> start(int memId, DateAndTime when) => i(
        () async {
          final receivedAct = await _actRepository.receive(
            Act(memId, DateAndTimePeriod(start: when)),
          );

          _registerStartNotifications(receivedAct.memId);

          return receivedAct;
        },
        [memId, when],
      );

  Future<Act> finish(int actId, DateAndTime when) => i(
        () async {
          final finishingAct = await _actRepository.shipById(actId);

          final replaced = await _actRepository.replace(
            finishingAct.copiedWith(
              finishingAct.period.copiedWith(when),
            ),
          );

          _cancelNotifications(replaced.memId);

          // ISSUE #226

          return replaced;
        },
        [actId, when],
      );

  Future<Act> edit(Act editingAct) => i(
        () async {
          final replaced = await _actRepository.replace(editingAct);

          if (replaced.period.end == null) {
            _registerStartNotifications(replaced.memId);
          } else {
            _cancelNotifications(replaced.memId);
          }

          return replaced;
        },
        editingAct,
      );

  Future<Act> delete(int id) => i(
        () async {
          final wasted = await ActRepository().wasteById(id);

          _cancelNotifications(wasted.memId);

          return wasted;
        },
        id,
      );

  Future _registerStartNotifications(int memId) => v(
        () async {
          final mem = await _memRepository.shipById(memId);

          _notificationRepository.receive(
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
              _notificationRepository.receive(
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
        },
        memId,
      );

  Future _cancelNotifications(int memId) => v(
        () async {
          await _notificationRepository.discard(activeActNotificationId(memId));
          await _notificationRepository
              .discard(afterActStartedNotificationId(memId));
        },
        memId,
      );

  ActService._(
    this._actRepository,
    this._memRepository,
    this._memNotificationRepository,
    this._notificationRepository,
    this._notificationClient,
  );

  static ActService? _instance;

  factory ActService() => _instance ??= ActService._(
        ActRepository(),
        MemRepository(),
        MemNotificationRepository(),
        NotificationRepository(),
        NotificationClient(),
      );
}
