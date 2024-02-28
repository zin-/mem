import 'dart:convert';

import 'package:mem/acts/act_service.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification/one_time_notification.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/show_notification.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/notification_repository.dart';

class ActsClient {
  final ActService _actService;

  final MemRepository _memRepository;
  final MemNotificationRepository _memNotificationRepository;

  final NotificationClientV2 _notificationClient;
  final NotificationRepository _notificationRepository;

  Future<SavedAct> start(
    int memId,
    DateAndTime when,
  ) =>
      v(
        () async {
          final startedAct = await _actService.start(memId, when);

          _registerStartNotifications(memId);

          return startedAct;
        },
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<SavedAct> edit(
    SavedAct savedAct,
  ) =>
      i(
        () async {
          final replaced = await _actService.edit(savedAct);

          if (replaced.period.end == null) {
            _registerStartNotifications(replaced.memId);
          } else {
            // _cancelNotifications(replaced.memId);
          }

          return replaced;
        },
        {
          "savedAct": savedAct,
        },
      );

  Future pause(int actId, DateAndTime when) => i(
        () async {
          final finished = await _actService.finish(actId, when);

          final mem = await _memRepository.shipById(finished.memId);

          await _notificationRepository.receive(
            ShowNotification(
              pausedActNotificationId(finished.memId),
              mem.name,
              "Paused",
              json.encode({memIdKey: mem.id}),
              [
                _notificationClient.startActAction,
              ],
              _notificationClient.pausedAct,
            ),
          );
        },
        {actId, when},
      );

  void _registerStartNotifications(int memId) => v(
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
        {
          "memId": memId,
        },
      );

  ActsClient._(
    this._actService,
    this._memRepository,
    this._memNotificationRepository,
    this._notificationClient,
    this._notificationRepository,
  );

  static ActsClient? _instance;

  factory ActsClient() => _instance ??= ActsClient._(
        ActService(),
        MemRepository(),
        MemNotificationRepository(),
        NotificationClientV2(),
        NotificationRepository(),
      );
}
