import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:timezone/data/latest_all.dart';

import 'icons.dart';
import 'notification/notification.dart';
import 'notification/show_notification.dart';
import 'wrapper.dart';

class NotificationRepository extends RepositoryV1<Notification, void> {
  final NotificationsWrapper? _flutterLocalNotificationsWrapper;

  Future<bool?> checkNotification() => v(
        () async => _flutterLocalNotificationsWrapper?.handleAppLaunchDetails(),
      );

  @override
  Future<void> receive(Notification entity) => v(
        () async {
          if (entity is ShowNotification) {
            await _flutterLocalNotificationsWrapper?.show(
              entity.id,
              entity.title,
              entity.body,
              entity.channel,
              entity.payload,
            );
          }
        },
        {
          "entity": entity,
        },
      );

  Future<void> discard(int notificationId) => v(
        () async => _flutterLocalNotificationsWrapper?.cancel(notificationId),
        {
          "notificationId": notificationId,
        },
      );

  NotificationRepository._(this._flutterLocalNotificationsWrapper);

  static NotificationRepository? _instance;

  factory NotificationRepository() => v(
        () {
          if (defaultTargetPlatform == TargetPlatform.android) {
            initializeTimeZones();
          }

          return _instance ??= NotificationRepository._(
            defaultTargetPlatform == TargetPlatform.android
                ? NotificationsWrapper(androidDefaultIconPath)
                : null,
          );
        },
      );
}
