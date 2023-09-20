import 'package:flutter/material.dart';
import 'package:mem/act_counter/act_counter_configure.dart';
import 'package:mem/act_counter/act_counter_repository.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/page.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/mems/mem_notification_repository.dart';
import 'package:mem/mems/mem_repository.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/notification_repository.dart';

import 'application.dart';

Future<void> main({String? languageCode}) => i(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await NotificationRepository().checkNotification();

        return _runApplication(languageCode: languageCode);
      },
      {'languageCode': languageCode},
    );

@pragma('vm:entry-point')
Future<void> launchMemDetailPage(int memId) => i(
      () {
        WidgetsFlutterBinding.ensureInitialized();

        return _runApplication(home: MemDetailPage(memId));
      },
      {'memId': memId},
    );

@pragma('vm:entry-point')
Future<void> launchActCounterConfigure() => i(
      () {
        WidgetsFlutterBinding.ensureInitialized();

        return _runApplication(home: const ActCounterConfigure());
      },
    );

Future<void> _runApplication({Widget? home, String? languageCode}) => i(
      () async {
        await openDatabase();
        ActCounterRepository();

        runApp(MemApplication(languageCode, home: home));
      },
      [home, languageCode],
    );

// FIXME Databaseに関わるRepositoryの初期化処理で勝手に読み込まれるべき
Future<void> openDatabase() async {
  final database = await DatabaseManager().open(databaseDefinition);

  MemRepository(
    database.getTable(defTableMems.name),
  );
  MemItemRepository(
    database.getTable(defTableMemItems.name),
  );
  ActRepository(
    database.getTable(defTableActs.name),
  );
  MemNotificationRepository(
    database.getTable(defTableMemNotifications.name),
  );
}

// FIXME HomeWidget関連の処理、場所が適切ではない
const uriSchema = 'mem';
const appId = 'zin.playground.mem';
const actCounter = 'act_counters';
const memIdParamName = 'mem_id';

Future<void> backgroundCallback(Uri? uri) => i(
      () async {
        NotificationClient();

        if (uri != null && uri.scheme == uriSchema && uri.host == appId) {
          await openDatabase();

          if (uri.pathSegments.contains(actCounter)) {
            final memId = uri.queryParameters[memIdParamName];

            if (memId != null) {
              await ActCounterService().increment(
                int.parse(memId),
                DateAndTime.now(),
              );
            }
          }
        }
      },
      {'uri': uri},
    );
