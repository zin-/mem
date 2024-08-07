import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository/key_with_value_repository.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/permissions/permission.dart';
import 'package:mem/permissions/permission_handler_wrapper.dart';
import 'package:mem/values/paths.dart';

import 'notification/notification.dart';
import 'flutter_local_notifications_wrapper.dart';

class NotificationRepository extends KeyWithValueRepository<Notification, int>
    with Discarder {
  FlutterLocalNotificationsWrapper? _flutterLocalNotificationsWrapper =
      defaultTargetPlatform == TargetPlatform.android
          ? FlutterLocalNotificationsWrapper(androidDefaultIconPath)
          : null;

  NotificationRepository._();

  static NotificationRepository? _instance;

  factory NotificationRepository() => v(
        () => _instance ??= NotificationRepository._(),
        {
          "_instance": _instance,
        },
      );

  static void resetSingleton() => v(
        () {
          FlutterLocalNotificationsWrapper.resetSingleton();
          _instance?._flutterLocalNotificationsWrapper = null;
          _instance = null;
        },
        {
          '_instance': _instance,
        },
      );

  Future<bool?> checkNotification() => v(
        () async => _flutterLocalNotificationsWrapper?.handleAppLaunchDetails(),
      );

  @override
  Future<bool> receive(Notification entity) => v(
        () async {
          if (await PermissionHandlerWrapper().grant(Permission.notification)) {
            await _flutterLocalNotificationsWrapper?.show(
              entity.key,
              entity.title,
              entity.body,
              entity.channel,
              entity.payload,
            );
            return true;
          } else {
            return false;
          }
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

  @override
  Future<void> discardAll() => v(
        () async {
          await _flutterLocalNotificationsWrapper?.cancelAll();
          await _flutterLocalNotificationsWrapper
              ?.deleteNotificationChannels(NotificationType.values.map(
            (e) => e.buildNotificationChannel().id,
          ));
        },
      );
}
