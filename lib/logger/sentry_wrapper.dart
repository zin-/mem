// テストにおいて実行しないため
// coverage:ignore-file
import 'dart:async';

import 'package:mem/logger/log_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryWrapper {
  Future<SentryWrapper> init(AppRunner appRunner) => v(
        () async {
          await SentryFlutter.init(
            (options) {
              options.dsn =
                  'https://ebb1b14bba388aa8401cf84de9242a5e@o4508056187830272.ingest.us.sentry.io/4508056200282112';
              // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
              // We recommend adjusting this value in production.
              options.tracesSampleRate = 1.0;
              // The sampling rate for profiling is relative to tracesSampleRate
              // Setting to 1.0 will profile 100% of sampled transactions:
              options.profilesSampleRate = 1.0;
            },
            appRunner: appRunner,
          );

          return SentryWrapper();
        },
      );

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
