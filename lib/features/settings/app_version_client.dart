import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/singleton.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_version.dart';

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=zin.playground.mem';

class AppVersionClient {
  Future<void> openStore() => v(
        () async {
          await launchUrl(
            Uri.parse(_playStoreUrl),
            mode: LaunchMode.externalApplication,
          );
        },
      );

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
