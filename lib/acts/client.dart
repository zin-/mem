import 'dart:convert';

import 'package:mem/acts/act_service.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/show_notification.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/notification_repository.dart';

class ActsClient {
  final NotificationClient _notificationClient;

  final ActService _actService;

  final MemRepository _memRepository;
  final NotificationRepository _notificationRepository;

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

  ActsClient._(
    this._notificationClient,
    this._actService,
    this._memRepository,
    this._notificationRepository,
  );

  static ActsClient? _instance;

  factory ActsClient() => _instance ??= ActsClient._(
        NotificationClient(),
        ActService(),
        MemRepository(),
        NotificationRepository(),
      );
}
