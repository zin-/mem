import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/settings/app_version_client.dart';
import 'package:mem/framework/singleton.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// pubspec の version。build と `+` でつないでタイルに出す
const _version = '0.5.36';
// pubspec の build number。空でないのでタイルに出す
const _buildNumber = '1';
const _shownVersion = '$_version+$_buildNumber';
// プラグインが version を空で返す。タイルは出さない
const _emptyVersion = '';

// このアプリの Google Play 詳細。iOS でも同じ URL を外部アプリで開く
const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=zin.playground.mem';

void main() {
  late UrlLauncherPlatform originalLauncher;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    originalLauncher = UrlLauncherPlatform.instance;
    Singleton.reset<AppVersionClient>();
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalLauncher;
  });

  group('AppVersionClient', () {
    test('returns version and build number from package info', () async {
      _mockPackageInfo(version: _version, buildNumber: _buildNumber);
      Singleton.reset<AppVersionClient>();

      expect((await AppVersionClient().current())?.text, _shownVersion);
    });

    test('is absent when package info version is empty', () async {
      _mockPackageInfo(version: _emptyVersion, buildNumber: _buildNumber);
      Singleton.reset<AppVersionClient>();

      expect(await AppVersionClient().current(), isNull);
    });

    test('opens the Play Store page in an external application', () async {
      final launcher = _RecordingUrlLauncher();
      UrlLauncherPlatform.instance = launcher;
      Singleton.reset<AppVersionClient>();

      await AppVersionClient().openStore();

      expect(launcher.url, _playStoreUrl);
      expect(launcher.mode, PreferredLaunchMode.externalApplication);
    });
  });
}

void _mockPackageInfo({
  required String version,
  required String buildNumber,
}) {
  // current() は version と buildNumber だけ読む。残りは API が要求する
  PackageInfo.setMockInitialValues(
    appName: 'mem',
    packageName: 'zin.playground.mem',
    version: version,
    buildNumber: buildNumber,
    buildSignature: '',
  );
}

class _RecordingUrlLauncher extends UrlLauncherPlatform {
  String? url;
  PreferredLaunchMode? mode;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    mode = options.mode;
    return true;
  }
}
