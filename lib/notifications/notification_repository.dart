import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository/key_with_value_repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/permissions/permission.dart';
import 'package:mem/permissions/permission_handler_wrapper.dart';
import 'package:mem/values/paths.dart';

import 'notification/notification.dart';
import 'flutter_local_notifications_wrapper.dart';

class NotificationRepository extends KeyWithValueRepository<Notification, int>
    with DiscardAll {
  final FlutterLocalNotificationsWrapper? _flutterLocalNotificationsWrapper =
      defaultTargetPlatform == TargetPlatform.android
          ? FlutterLocalNotificationsWrapper(androidDefaultIconPath)
          : null;

  @override
  Future<void> receive(Notification entity) => v(
        () async {
          if (await PermissionHandlerWrapper().grant(Permission.notification)) {
            await _flutterLocalNotificationsWrapper?.show(
              entity.key,
              entity.title,
              entity.body,
              entity.channel,
              entity.payload,
            );
          }
        },
        {
          'entity': entity,
        },
      );

  Future<bool?> ship() => v(
        () async =>
            await _flutterLocalNotificationsWrapper?.handleAppLaunchDetails(),
      );

  @override
  Future<void> discard(int key) => v(
        () async => await _flutterLocalNotificationsWrapper?.cancel(key),
        {
          'key': key,
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

  static void reset() => v(
        () {
          FlutterLocalNotificationsWrapper.resetSingleton();
        },
      );
}
