import 'package:flutter/services.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/permissions/permission.dart';
import 'package:mem/values/constants.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

class PermissionHandlerWrapper {
  static PermissionHandlerWrapper? _instance;

  PermissionHandlerWrapper._();

  factory PermissionHandlerWrapper() =>
      _instance ??= PermissionHandlerWrapper._();

  Future<bool> check(Permission permission) => v(
        () async {
          final p = permission.convert();
          // Background serviceから実行した際に
          // MethodChannel('zin.playground.mem')が利用できないため
          // permission_handlerを用いて権限をチェックする
          return await p.isGranted;
        },
        {
          'permission': permission,
        },
      );

  Future<bool> request([List<Permission> permissions = const []]) => v(
        () async {
          try {
            final bool granted = await methodChannel.invokeMethod(
              requestPermissions,
              {
                permissionNames:
                    permissions.map((e) => e.name).toList(growable: false),
              },
            );

            return granted;
          } on MissingPluginException catch (e) {
            warn(e.message);
            return await Future.wait(permissions.map((e) => check(e))).then(
              (v) => v.every((isGranted) => isGranted == true),
            );
          } on PlatformException catch (e) {
            warn("Failed to request permission: ${e.message}");
            return false;
          }
        },
        {
          'permissions': permissions,
        },
      );
}

extension on Permission {
  permission_handler.Permission convert() {
    switch (this) {
      case Permission.notification:
        return permission_handler.Permission.notification;
    }
  }
}
