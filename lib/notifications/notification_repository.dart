import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository/key_with_value_repository.dart';
import 'package:mem/logger/log_service.dart';

import 'icons.dart';
import 'notification/notification.dart';
import 'wrapper.dart';

class NotificationRepository extends KeyWithValueRepository<Notification, int> {
  late final NotificationsWrapper? _flutterLocalNotificationsWrapper =
      defaultTargetPlatform == TargetPlatform.android
          ? NotificationsWrapper(androidDefaultIconPath)
          : null;

  NotificationRepository._();

  static NotificationRepository? _instance;

  factory NotificationRepository() => v(
        () => _instance ??= NotificationRepository._(),
        {
          "_instance": _instance,
        },
      );

  Future<bool?> checkNotification() => v(
        () async => _flutterLocalNotificationsWrapper?.handleAppLaunchDetails(),
      );

  @override
  Future<bool> receive(Notification entity) => v(
        () async {
          await _flutterLocalNotificationsWrapper?.show(
            entity.key,
            entity.title,
            entity.body,
            entity.channel,
            entity.payload,
          );

          return true;
        },
        {
          "entity": entity,
        },
      );

  @override
  Future<bool> discard(int key) => v(
        () async {
          _flutterLocalNotificationsWrapper?.cancel(key);

          return true;
        },
        {
          "key": key,
        },
      );
}
