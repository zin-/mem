import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/definition.dart';
import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/wrapper.dart';
import 'package:mem/values/durations.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testNotificationScenario();
}

const _scenarioName = "Notification scenario";

void testNotificationScenario() => group(": $_scenarioName", () {
      const insertedMemName = "$_scenarioName - mem name - inserted";

      late final Database db;
      int? insertedMemId;

      setUpAll(() async {
        db = await DatabaseManager(onTest: true).open(databaseDefinition);
      });
      setUp(() async {
        await resetDatabase(db);

        insertedMemId = await db.getTable(memTableDefinition.name).insert({
          defMemName.name: insertedMemName,
          createdAtColDef.name: DateTime(0),
        });
      });

      testWidgets(
        ": show MemDetailPage.",
        (widgetTester) async {
          final details = NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: memStartNotificationId(insertedMemId!),
            payload: json.encode({memIdKey: insertedMemId}),
          );

          onDidReceiveNotificationResponse(details);

          await Future.delayed(
            defaultTransitionDuration,
            () async {
              await widgetTester.pumpAndSettle(defaultTransitionDuration);

              expect(
                (widgetTester.widget(memNameOnDetailPageFinder)
                        as TextFormField)
                    .initialValue,
                insertedMemName,
              );
              expect(1, 1);
            },
          );
        },
      );
    });
