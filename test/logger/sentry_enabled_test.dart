import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/logger/sentry_wrapper.dart';

void main() {
  group('computeSentryErrorReportEnabled (#549)', () {
    test(': debug (isDebugMode true) disables Sentry.', () {
      expect(
        computeSentryErrorReportEnabled(
          disableErrorReport: false,
          isDebugMode: true,
        ),
        isFalse,
      );
    });

    test(': disableErrorReport true and isDebugMode true returns false.', () {
      expect(
        computeSentryErrorReportEnabled(
          disableErrorReport: true,
          isDebugMode: true,
        ),
        isFalse,
      );
    });

    test(': profile and release (isDebugMode false) enable Sentry.', () {
      expect(
        computeSentryErrorReportEnabled(
          disableErrorReport: false,
          isDebugMode: false,
        ),
        isTrue,
      );
    });

    test(': disableErrorReport true and isDebugMode false returns false.', () {
      expect(
        computeSentryErrorReportEnabled(
          disableErrorReport: true,
          isDebugMode: false,
        ),
        isFalse,
      );
    });
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

  group('SentryWrapper.sendTestException', () {
    test(': is no-op when sentry error report is disabled.', () async {
      expect(sentryErrorReportEnabled(), isFalse);

      final result = await SentryWrapper().sendTestException(
        'test',
        StackTrace.current,
      );

      expect(result, '');
    });
  });
}
