import 'package:mem/logger/log_service.dart';
import 'package:mem/permissions/permission.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

class PermissionHandlerWrapper {
  Future<bool> grant(Permission permission) => v(
        () async {
          final p = permission.convert();
          return await p.isGranted ? true : await p.request().isGranted;
        },
        {'permission': permission},
      );
}

extension on Permission {
  permission_handler.Permission convert() {
    switch (this) {
      case Permission.notification:
        return permission_handler.Permission.notification;
      default:
        throw UnimplementedError(toString());
    }
  }
}
