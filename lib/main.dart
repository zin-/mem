import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/workmanager_wrapper.dart';
import 'package:mem/framework/notifications/mem_notifications.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/framework/notifications/notification_client.dart';

import 'features/acts/counter/act_counter_client.dart';
import 'application.dart';
import 'framework/date_and_time/date_and_time.dart';
import 'features/logger/log_service.dart';
import 'framework/notifications/flutter_local_notifications_wrapper.dart';
import 'framework/notifications/notification_actions.dart';
import 'framework/notifications/notification_repository.dart';
import 'router.dart';

Future<void> main({String? languageCode}) async =>
    await _runApplication(languageCode: languageCode);

@pragma('vm:entry-point')
Future<void> launchActCounterConfigure() async {
  return await _runApplication(
    initialPath: newActCountersPath,
  );
}

Future<void> _runApplication({
  String? initialPath,
  String? languageCode,
}) =>
    i(
      () async {
        return await LogService(
          enableErrorReport: true,
        ).init(
          () async {
            WidgetsFlutterBinding.ensureInitialized();
            WorkmanagerWrapper(
              callbackDispatcher: workmanagerCallbackDispatcher,
            );

            if (initialPath != null ||
                await NotificationRepository().ship() == false) {
              return runApp(
                ProviderScope(
                  child: MemApplication(
                    initialPath: initialPath,
                    languageCode: languageCode,
                  ),
                ),
              );
            }
          },
        );
      },
      {
        'initialPath': initialPath,
        'languageCode': languageCode,
      },
    );

@pragma('vm:entry-point')
Future<void> onNotificationResponseReceived(dynamic details) async {
  await LogService(
    enableErrorReport: true,
  ).init(
    () async {
      WorkmanagerWrapper(callbackDispatcher: workmanagerCallbackDispatcher);

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

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() =>
    LogService(enableErrorReport: true).init(
      () => WorkmanagerWrapper().executeTask(
        (inputData) => v(
          () async {
            final notificationTypeName = inputData?[notificationTypeKey];
            final memId = inputData?[memIdKey] as int?;

            if (notificationTypeName == null) {
              return false;
            } else {
              await NotificationClient().show(
                NotificationType.values.singleWhere(
                  (element) => element.name == notificationTypeName,
                ),
                memId,
              );

              return true;
            }
          },
          {
            'inputData': inputData,
          },
        ),
      ),
    );
