import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/counter/act_counter_client.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/flutter_local_notifications_wrapper.dart';
import 'package:mem/notifications/notification_actions.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/router.dart';

import 'application.dart';

Future<void> main({String? languageCode}) async {
  return _runApplication(languageCode: languageCode);
}

@pragma('vm:entry-point')
Future<void> launchActCounterConfigure() {
  return _runApplication(
    initialPath: newActCountersPath,
  );
}

Future<void> _runApplication({
  String? initialPath,
  String? languageCode,
}) =>
    i(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await LogService(
          enableErrorReport: true,
        ).init(
          () => runApp(
            ProviderScope(
              child: MemApplication(
                initialPath: initialPath,
                languageCode: languageCode,
              ),
            ),
          ),
        );

        await NotificationRepository().ship();
      },
      {
        'initialPath': initialPath,
        'languageCode': languageCode,
      },
    );

@pragma('vm:entry-point')
Future<void> onNotificationResponseReceived(dynamic details) async {
  WidgetsFlutterBinding.ensureInitialized();

  await LogService(enableErrorReport: true).init(
    () async {
      await onDidReceiveNotificationResponse(
        details,
        (memId) => v(
          () async {
            if (memId is int) {
              await _runApplication(
                initialPath: buildMemDetailPath(memId),
              );
            }
          },
          {
            'memId': memId,
          },
        ),
        (actionId, memId) => v(
          () async {
            if (actionId is String && memId is int) {
              await buildNotificationActions()
                  .singleWhere(
                    (e) => e.id == actionId,
                  )
                  .onTapped(memId);
            }
          },
          {
            'actionId': actionId,
            'memId': memId,
          },
        ),
      );
    },
  );
}

// FIXME HomeWidget関連の処理、場所が適切ではない
const uriSchema = 'mem';
const appId = 'zin.playground.mem';
const actCounter = 'act_counters';
const memIdParamName = 'mem_id';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();

  await LogService(enableErrorReport: true).init(
    () async {
      if (uri != null && uri.scheme == uriSchema && uri.host == appId) {
        if (uri.pathSegments.contains(actCounter)) {
          final memId = uri.queryParameters[memIdParamName];

          if (memId != null) {
            await ActCounterClient().increment(
              int.parse(memId),
              DateAndTime.now(),
            );
          }
        }
      }
    },
  );
}
