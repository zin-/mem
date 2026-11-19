import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/settings/app_version_client.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Singleton.reset<AppVersionClient>();
  });

  // PackageInfo.fromPlatform は成功をプロセス内にキャッシュする。
  // モックしたテストと同じファイルだと、未実装でも例外にならない。
  test('is absent when package info is unavailable', () async {
    expect(await AppVersionClient().current(), isNull);
  });
}
