import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart';

import 'icons.dart';
import 'notification/cancel_notification.dart';
import 'notification/notification.dart';
import 'notification/one_time_notification.dart';
import 'notification/repeated_notification.dart';
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
          if (entity is RepeatedNotification) {
            await _flutterLocalNotificationsWrapper?.zonedSchedule(
              entity.id,
              entity.title,
              entity.body,
              TZDateTime.from(entity.notifyFirstAt, local),
              entity.payloadJson,
              entity.actions,
              entity.channel,
              entity.interval,
            );
          } else if (entity is OneTimeNotification) {
            await _flutterLocalNotificationsWrapper?.zonedSchedule(
              entity.id,
              entity.title,
              entity.body,
              TZDateTime.from(entity.notifyAt, local),
              entity.payloadJson,
              entity.actions,
              entity.channel,
            );
          } else if (entity is ShowNotification) {
            await _flutterLocalNotificationsWrapper?.show(
              entity.id,
              entity.title,
              entity.body,
              entity.actions,
              entity.channel,
              entity.payloadJson,
            );
          } else if (entity is CancelNotification) {
            await discard(entity.id);
          }
        },
        entity,
      );

  Future<void> discard(int notificationId) => v(
        () async => _flutterLocalNotificationsWrapper?.cancel(notificationId),
        notificationId,
      );

  NotificationRepository._(this._flutterLocalNotificationsWrapper);

  static NotificationRepository? _instance;

  factory NotificationRepository() {
    initializeTimeZones();

    return _instance ??= NotificationRepository._(
      defaultTargetPlatform == TargetPlatform.android
          ? NotificationsWrapper(androidDefaultIconPath)
          : null,
    );
  }
}
