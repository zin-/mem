import 'package:mem/logger/log_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryWrapper {
  Future<String> captureException(
    dynamic throwable,
    dynamic stackTrace,
  ) =>
      v(
        () async => await Sentry.captureException(
          throwable,
          stackTrace: stackTrace,
        ).then(
          (v) => v.toString(),
        ),
        {
          'throwable': throwable,
          'stackTrace': stackTrace,
        },
      );
}
