import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/log_service.dart';

void main() {
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
