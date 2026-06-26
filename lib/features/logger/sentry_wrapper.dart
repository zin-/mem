// テストにおいて実行しないため
// coverage:ignore-file
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry エラー報告の有効判定（#549）。
///
/// [isDebugMode] は通常 [kDebugMode] を渡す。debug（`flutter run`）のみ無効。
/// profile（`flutter run --profile`）と release は [isDebugMode] が false のため有効。
/// #549 の「ローカル」は日常の debug 開発を指し、profile は本番相当として送信を維持する。
bool computeSentryErrorReportEnabled({
  required bool disableErrorReport,
  required bool isDebugMode,
}) =>
    !disableErrorReport && !isDebugMode;

/// [computeSentryErrorReportEnabled] を [kDebugMode] で評価する。
bool sentryErrorReportEnabled({bool disableErrorReport = false}) =>
    computeSentryErrorReportEnabled(
      disableErrorReport: disableErrorReport,
      isDebugMode: kDebugMode,
    );

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
