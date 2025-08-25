import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/counter/act_counter_entity.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/main.dart';

import '../helpers.dart';

const _name = "ActCounter test";

void main() => group(
      _name,
      () {
        const insertedMemName = '$_name: inserted - mem name';
        const insertedMemName2 = '$_name: inserted - mem name - 2';
        late int insertedMemId;
        late DateTime actStart;

        late final DatabaseAccessor dbA;

        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });
        setUp(() async {
          await clearAllTestDatabaseRows(databaseDefinition);

          insertedMemId = await dbA.insert(
            defTableMems,
            {
              defColMemsName.name: insertedMemName,
              defColCreatedAt.name: zeroDate,
            },
          );
          await dbA.insert(
            defTableMems,
            {
              defColMemsName.name: insertedMemName2,
              defColCreatedAt.name: zeroDate,
            },
          );
          await dbA.insert(
            defTableActs,
            {
              defFkActsMemId.name: insertedMemId,
              defColActsStart.name: zeroDate,
              defColActsStartIsAllDay.name: 0,
              defColCreatedAt.name: zeroDate,
            },
          );
          await dbA.insert(
            defTableActs,
            {
              defFkActsMemId.name: insertedMemId,
              defColActsStart.name: actStart = DateTime.now(),
              defColActsStartIsAllDay.name: 0,
              defColCreatedAt.name: zeroDate,
            },
          );
        });

        testWidgets(
          ': select saved mem.',
          (widgetTester) async {
            // var initializeCount = 0;
            // var saveWidgetDataCount = 0;
            // var updateWidgetCount = 0;
            // final homeWidgetId = randomInt();
            // final actCounter =
            //     ActCounterEntity(insertedMemId, insertedMemName, 1, actStart);

            // widgetTester.binding.defaultBinaryMessenger
            //     .setMockMethodCallHandler(
            //   MethodChannel(actCounter.methodChannelName),
            //   (message) {
            //     expect(message.method, actCounter.initializeMethodName);
            //     expect(message.arguments, null);

            //     initializeCount++;
            //     return Future.value(homeWidgetId);
            //   },
            // );
            // final saveWidgetDataArgs = {
            //   0: {
            //     'id': "memName-$insertedMemId",
            //     'data': insertedMemName,
            //   },
            //   1: {
            //     'id': "actCount-$insertedMemId",
            //     // length of inserted acts
            //     'data': 1,
            //   },
            //   2: {
            //     'id': "lastUpdatedAtSeconds-$insertedMemId",
            //     'data': actStart.millisecondsSinceEpoch.toDouble(),
            //   },
            //   3: {
            //     'id': "memId-$homeWidgetId",
            //     'data': insertedMemId,
            //   },
            // };
            // widgetTester.binding.defaultBinaryMessenger
            //     .setMockMethodCallHandler(
            //   const MethodChannel('home_widget'),
            //   (message) {
            //     if (message.method == 'registerBackgroundCallback') {
            //       return Future.value(true);
            //     } else if (message.method == 'saveWidgetData') {
            //       expect(
            //         message.arguments,
            //         saveWidgetDataArgs[saveWidgetDataCount],
            //       );

            //       saveWidgetDataCount++;
            //       return Future.value(true);
            //     } else if (message.method == 'updateWidget') {
            //       expect(
            //         message.arguments,
            //         {
            //           'name': "ActCounterProvider",
            //           'android': null,
            //           'ios': null,
            //           'qualifiedAndroidName': null,
            //         },
            //       );

            //       updateWidgetCount++;
            //       return Future.value(true);
            //     }

            //     throw UnimplementedError();
            //   },
            // );

            await launchActCounterConfigure();
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(Text).at(0)) as Text).data,
              'Select target',
            );
            expect(
              (widgetTester.widget(find.byType(RadioGroup<int>).at(0))
                      as RadioGroup)
                  .groupValue,
              null,
            );
            expect(
              (widgetTester.widget(find.byType(RadioGroup<int>).at(1))
                      as RadioGroup)
                  .groupValue,
              null,
            );
            await widgetTester.tap(find.text(insertedMemName2));
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(RadioGroup<int>).at(0))
                      as RadioGroup)
                  .groupValue,
              null,
            );
            expect(
              (widgetTester.widget(find.byType(RadioGroup<int>).at(1))
                      as RadioGroup)
                  .groupValue,
              insertedMemId2,
            );
            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(RadioGroup<int>).at(0))
                      as RadioGroup)
                  .groupValue,
              insertedMemId,
            );
            expect(
              (widgetTester.widget(find.byType(RadioGroup<int>).at(1))
                      as RadioGroup)
                  .groupValue,
              null,
            );
            await widgetTester.tap(find.byIcon(Icons.check).first);
            await widgetTester.pumpAndSettle();

            // if (defaultTargetPlatform == TargetPlatform.android) {
            //   // await expectLater(initializeCount, 1);
            //   // await expectLater(saveWidgetDataCount, 4);
            //   // await expectLater(updateWidgetCount, 1);
            // } else {
            //   await expectLater(initializeCount, 0);
            //   await expectLater(saveWidgetDataCount, 0);
            //   await expectLater(updateWidgetCount, 0);
            // }
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
                "id": "memName-$insertedMemId",
                "data": insertedMemName,
              },
              1: {
                "id": "actCount-$insertedMemId",
                // length of inserted acts
                "data": 1,
              },
              2: {
                "id": "lastUpdatedAtSeconds-$insertedMemId",
                "data": isNotNull,
              },
            };
            widgetTester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(
              const MethodChannel("home_widget"),
              (message) {
                if (message.method == "registerBackgroundCallback") {
                  return Future.value(true);
                } else if (message.method == "saveWidgetData") {
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
                      "name": "ActCounterProvider",
                      "android": null,
                      "ios": null,
                      "qualifiedAndroidName": null,
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
