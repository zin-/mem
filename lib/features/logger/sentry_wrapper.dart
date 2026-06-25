// テストにおいて実行しないため
// coverage:ignore-file
import 'dart:async';

import 'package:mem/features/logger/log_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryWrapper {
  static bool _initialized = false;
  static Future<void>? _initializing;

  static void _configureOptions(SentryFlutterOptions options) {
    options.dsn =
        'https://ebb1b14bba388aa8401cf84de9242a5e@o4508056187830272.ingest.us.sentry.io/4508056200282112';
    // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
    // We recommend adjusting this value in production.
    options.tracesSampleRate = 1.0;
  }

  Future<void> _ensureInitialized({AppRunner? appRunner}) async {
    if (_initialized) {
      if (appRunner != null) {
        await appRunner();
      }
      return;
    }
    _initializing ??= SentryFlutter.init(
      _configureOptions,
      appRunner: appRunner ?? () async {},
    ).then((_) {
      _initialized = true;
    }).catchError((Object error, StackTrace stackTrace) {
      _initializing = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
    await _initializing;
  }

  Future<SentryWrapper> init(AppRunner appRunner) => v(
        () async {
          await _ensureInitialized(appRunner: appRunner);
          return SentryWrapper();
        },
      );

  Future<String> sendTestException(
    dynamic throwable,
    dynamic stackTrace,
  ) async {
    if (!sentryErrorReportEnabled()) {
      return '';
    }
    return captureException(throwable, stackTrace);
  }

  Future<String> captureException(
    dynamic throwable,
    dynamic stackTrace,
  ) =>
      v(
        () async {
          await _ensureInitialized();
          return (await Sentry.captureException(
            throwable,
            stackTrace: stackTrace,
          ))
              .toString();
        },
        {
          'throwable': throwable,
          'stackTrace': stackTrace,
        },
      );
}
