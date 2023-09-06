import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/act_counter/act_counter_repository.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/main.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testActCounterConfigure();
}

const _scenarioName = "ActCounter test";

void testActCounterConfigure() => group(
      ': $_scenarioName',
      () {
        const insertedMemName = '$_scenarioName: inserted - mem name';
        const insertedMemName2 = '$_scenarioName: inserted - mem name - 2';
        late int insertedMemId;
        late int insertedMemId2;
        late DateTime actPeriod;

        late final Database db;

        setUpAll(() async {
          db = await DatabaseManager(onTest: true).open(databaseDefinition);
        });
        setUp(() async {
          await resetDatabase(db);

          final memsTable = db.getTable(memTableDefinition.name);
          insertedMemId = await memsTable.insert({
            defMemName.name: insertedMemName,
            createdAtColDef.name: zeroDate,
          });
          insertedMemId2 = await memsTable.insert({
            defMemName.name: insertedMemName2,
            createdAtColDef.name: zeroDate,
          });
          final actsTable = db.getTable(actTableDefinition.name);
          await actsTable.insert({
            fkDefMemId.name: insertedMemId,
            defActStart.name: zeroDate,
            defActStartIsAllDay.name: 0,
            createdAtColDef.name: zeroDate,
          });
          await actsTable.insert({
            fkDefMemId.name: insertedMemId,
            defActStart.name: actPeriod = DateTime.now(),
            defActStartIsAllDay.name: 0,
            createdAtColDef.name: zeroDate,
          });
        });

        testWidgets(
          ': select saved mem.',
          (widgetTester) async {
            var initializeCount = 0;
            var saveWidgetDataCount = 0;
            var updateWidgetCount = 0;
            final homeWidgetId = randomInt();
            widgetTester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(
              const MethodChannel(methodChannelName),
              (message) {
                expect(message.method, initializeMethodName);
                expect(message.arguments, null);

                initializeCount++;
                return Future.value(homeWidgetId);
              },
            );
            final saveWidgetDataArgs = {
              0: {
                'id': "memName-$insertedMemId",
                'data': insertedMemName,
              },
              1: {
                'id': "actCount-$insertedMemId",
                // length of inserted acts
                'data': 1,
              },
              2: {
                'id': "lastUpdatedAtSeconds-$insertedMemId",
                'data': actPeriod.millisecondsSinceEpoch.toDouble(),
              },
              3: {
                'id': "memId-$homeWidgetId",
                'data': insertedMemId,
              },
            };
            widgetTester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(
              const MethodChannel('home_widget'),
              (message) {
                if (message.method == 'registerBackgroundCallback') {
                  return Future.value(true);
                } else if (message.method == 'saveWidgetData') {
                  expect(
                    message.arguments,
                    saveWidgetDataArgs[saveWidgetDataCount],
                  );

                  saveWidgetDataCount++;
                  return Future.value(true);
                } else if (message.method == 'updateWidget') {
                  expect(
                    message.arguments,
                    {
                      'name': "ActCounterProvider",
                      'android': null,
                      'ios': null,
                      'qualifiedAndroidName': null,
                    },
                  );

                  updateWidgetCount++;
                  return Future.value(true);
                }

                throw UnimplementedError();
              },
            );

            await launchActCounterConfigure();
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(Text).at(0)) as Text).data,
              'Select target',
            );
            expect(
              (widgetTester.widget(find.byType(Radio<int>).at(0)) as Radio)
                  .groupValue,
              null,
            );
            expect(
              (widgetTester.widget(find.byType(Radio<int>).at(1)) as Radio)
                  .groupValue,
              null,
            );
            await widgetTester.tap(find.text(insertedMemName2));
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(Radio<int>).at(0)) as Radio)
                  .groupValue,
              null,
            );
            expect(
              (widgetTester.widget(find.byType(Radio<int>).at(1)) as Radio)
                  .groupValue,
              insertedMemId2,
            );
            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(Radio<int>).at(0)) as Radio)
                  .groupValue,
              insertedMemId,
            );
            expect(
              (widgetTester.widget(find.byType(Radio<int>).at(1)) as Radio)
                  .groupValue,
              null,
            );
            await widgetTester.tap(find.byIcon(Icons.check));
            await widgetTester.pumpAndSettle();

            if (defaultTargetPlatform == TargetPlatform.android) {
              await expectLater(initializeCount, 1);
              await expectLater(saveWidgetDataCount, 4);
              await expectLater(updateWidgetCount, 1);
            } else {
              await expectLater(initializeCount, 0);
              await expectLater(saveWidgetDataCount, 0);
              await expectLater(updateWidgetCount, 0);
            }
          },
        );

        testWidgets(
          ": increment.",
          (widgetTester) async {
            final uri = Uri(
              scheme: uriSchema,
              host: appId,
              pathSegments: [actCounter],
              queryParameters: {
                memIdParamName: insertedMemId.toString(),
              },
            );

            var saveWidgetDataCount = 0;
            var updateWidgetCount = 0;

            final saveWidgetDataArgs = {
              0: {
                'id': "memName-$insertedMemId",
                'data': insertedMemName,
              },
              1: {
                'id': "actCount-$insertedMemId",
                // length of inserted acts
                'data': 2,
              },
              2: {
                'id': "lastUpdatedAtSeconds-$insertedMemId",
                'data': isNotNull,
              },
            };
            widgetTester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(
              const MethodChannel('home_widget'),
              (message) {
                if (message.method == 'registerBackgroundCallback') {
                  return Future.value(true);
                } else if (message.method == 'saveWidgetData') {
                  expect(
                    message.arguments,
                    saveWidgetDataArgs[saveWidgetDataCount],
                  );

                  saveWidgetDataCount++;
                  return Future.value(true);
                } else if (message.method == 'updateWidget') {
                  expect(
                    message.arguments,
                    {
                      'name': "ActCounterProvider",
                      'android': null,
                      'ios': null,
                      'qualifiedAndroidName': null,
                    },
                  );

                  updateWidgetCount++;
                  return Future.value(true);
                }

                throw UnimplementedError();
              },
            );

            await backgroundCallback(uri);

            if (defaultTargetPlatform == TargetPlatform.android) {
              await expectLater(saveWidgetDataCount, 3);
              await expectLater(updateWidgetCount, 1);
            } else {
              await expectLater(saveWidgetDataCount, 0);
              await expectLater(updateWidgetCount, 0);
            }
          },
        );
      },
    );
