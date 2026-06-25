import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/log_service.dart';

void main() {
  group('computeSentryErrorReportEnabled', () {
    test(': disableErrorReport false and isDebugMode true returns false.', () {
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

    test(': disableErrorReport false and isDebugMode false returns true.', () {
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
}
