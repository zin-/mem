import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/sentry_wrapper.dart';

import '../helpers.dart';

typedef _SentryEnabledInput = ({
  bool disableErrorReport,
  bool isDebugMode,
});

void main() {
  group('computeSentryErrorReportEnabled (#549)', () {
    for (final testCase in [
      TestCase<_SentryEnabledInput, bool>(
        name: 'debug (isDebugMode true) disables Sentry',
        (
          disableErrorReport: false,
          isDebugMode: true,
        ),
        false,
      ),
      TestCase<_SentryEnabledInput, bool>(
        name: 'disableErrorReport true and isDebugMode true returns false',
        (
          disableErrorReport: true,
          isDebugMode: true,
        ),
        false,
      ),
      TestCase<_SentryEnabledInput, bool>(
        name: 'profile and release (isDebugMode false) enable Sentry',
        (
          disableErrorReport: false,
          isDebugMode: false,
        ),
        true,
      ),
      TestCase<_SentryEnabledInput, bool>(
        name: 'disableErrorReport true and isDebugMode false returns false',
        (
          disableErrorReport: true,
          isDebugMode: false,
        ),
        false,
      ),
    ]) {
      test(': ${testCase.name}.', () {
        expect(
          computeSentryErrorReportEnabled(
            disableErrorReport: testCase.input.disableErrorReport,
            isDebugMode: testCase.input.isDebugMode,
          ),
          testCase.expected,
        );
      });
    }
  });

  group('sentryErrorReportEnabled', () {
    test(': kDebugMode is true by default in flutter test.', () {
      expect(sentryErrorReportEnabled(), isFalse);
    });

    test(': disableErrorReport overrides to false.', () {
      expect(
        sentryErrorReportEnabled(disableErrorReport: true),
        isFalse,
      );
    });
  });
}
