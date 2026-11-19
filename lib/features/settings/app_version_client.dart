import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/singleton.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_version.dart';

class AppVersionClient {
  Future<AppVersion?> current() => v(
        () async {
          try {
            final info = await PackageInfo.fromPlatform();
            return AppVersion.of(
              version: info.version,
              buildNumber: info.buildNumber,
            );
          } on Exception {
            // プラグイン未実装のテストでは取れない。タイルは出さない
            return null;
          }
        },
      );

  AppVersionClient._();

  factory AppVersionClient({
    AppVersionClient? mock,
  }) {
    if (mock != null) {
      Singleton.override<AppVersionClient>(mock);
      return mock;
    }
    return Singleton.of(() => AppVersionClient._());
  }
}
