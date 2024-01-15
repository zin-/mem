import 'dart:convert';

import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
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
  final NotificationClientV2 _notificationClient;

  Future<SavedAct> start(int memId, DateAndTime when) => i(
        () async {
          final receivedAct = await _actRepository.receive(
            Act(memId, DateAndTimePeriod(start: when)),
          );

          _registerStartNotifications(receivedAct.memId);

          return receivedAct;
        },
        [memId, when],
      );

  Future<SavedAct> finish(int actId, DateAndTime when) => i(
        () async {
          final finishingAct = await _actRepository.shipById(actId);

          final replaced = await _actRepository.replace(
            finishingAct.copiedWith(
              () => finishingAct.period.copiedWith(when),
            ),
          );

          _cancelNotifications(replaced.memId);

          // ISSUE #226

          return replaced;
        },
        [actId, when],
      );

  Future<SavedAct> edit(SavedAct editingAct) => i(
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

  Future<SavedAct> delete(int id) => i(
        () async {
          final wasted = await _actRepository.wasteById(id);

          _cancelNotifications(wasted.memId);

          return wasted;
        },
        id,
      );

  Future _registerStartNotifications(int memId) => v(
        () async {
          final memName = (await _memRepository.shipById(memId)).name;

          _notificationRepository.receive(
            ShowNotification(
              activeActNotificationId(memId),
              memName,
              'Running',
              json.encode({memIdKey: memId}),
              [
                _notificationClient.finishActiveActAction,
                _notificationClient.pauseAct,
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
                  memName,
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
        NotificationClientV2(),
      );
}
