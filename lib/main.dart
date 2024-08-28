import 'package:flutter/material.dart';
import 'package:mem/act_counter/act_counter_client.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/flutter_local_notifications_wrapper.dart';
import 'package:mem/notifications/notification_actions.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/router.dart';

import 'application.dart';

Future<void> main({String? languageCode}) => i(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await NotificationRepository().checkNotification();

        return _runApplication(languageCode: languageCode);
      },
      {'languageCode': languageCode},
    );

Future<void> launchMemDetailPage(int memId) => i(
      () {
        WidgetsFlutterBinding.ensureInitialized();

        return _runApplication(
          initialPath: buildMemDetailPath(memId),
        );
      },
      {'memId': memId},
    );

@pragma('vm:entry-point')
Future<void> launchActCounterConfigure() => i(
      () {
        WidgetsFlutterBinding.ensureInitialized();

        return _runApplication(
          initialPath: newActCountersPath,
        );
      },
    );

@pragma('vm:entry-point')
Future<void> onNotificationResponseReceived(dynamic details) => i(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await onDidReceiveNotificationResponse(
          details,
          (memId) => v(
            () async {
              if (memId is int) {
                await launchMemDetailPage(memId);
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
      {'details': details},
    );

Future<void> _runApplication({
  String? languageCode,
  String? initialPath,
}) =>
    i(
      () async {
        runApp(
          MemApplication(
            initialPath: initialPath,
          ),
        );
      },
      {
        'languageCode': languageCode,
        'initialPath': initialPath,
      },
    );

// FIXME HomeWidget関連の処理、場所が適切ではない
const uriSchema = 'mem';
const appId = 'zin.playground.mem';
const actCounter = 'act_counters';
const memIdParamName = 'mem_id';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) => i(
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
      {'uri': uri},
    );
