import 'package:mem/features/settings/app_version.dart';
import 'package:test/test.dart';

void main() {
  group('AppVersion', () {
    test('is absent when version or build number is empty', () {
      expect(AppVersion.of(version: '', buildNumber: '1'), isNull);
      expect(AppVersion.of(version: '0.5.36', buildNumber: ''), isNull);
    });

    test('shows version and build number', () {
      expect(
        AppVersion.of(version: '0.5.36', buildNumber: '1')?.text,
        '0.5.36+1',
      );
    });
  });
}
