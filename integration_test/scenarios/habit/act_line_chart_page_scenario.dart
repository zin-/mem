import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/acts_summary.dart';
import 'package:mem/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/acts/line_chart/states.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';

import '../helpers.dart';

const _name = "ActLineChartPage scenario";

void main() => group(_name, () {
      const insertedMemName = '$_name: inserted mem - name';

      late final DatabaseAccessor dbA;
      late final int insertedMemId;

      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
        await clearAllTestDatabaseRows(databaseDefinition);

        insertedMemId = await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: insertedMemName,
            defColCreatedAt.name: zeroDate,
          },
        );
      });

      setUp(() async {
        await dbA.delete(defTableActs);

        final now = DateTime.now();

        await dbA.insert(
          defTableActs,
          {
            defFkActsMemId.name: insertedMemId,
            defColActsStart.name: DateTime(now.year, now.month - 1, 28),
            defColActsStartIsAllDay.name: 0,
            defColActsEnd.name: now,
            defColActsEndIsAllDay.name: 0,
            defColCreatedAt.name: zeroDate,
          },
        );
        for (int i = 0; i < 49; i++) {
          final start = now.subtract(Duration(days: i));
          for (int j = 0; j < randomInt(5); j++) {
            await dbA.insert(
              defTableActs,
              {
                defFkActsMemId.name: insertedMemId,
                defColActsStart.name: start,
                defColActsStartIsAllDay.name: 0,
                defColActsEnd.name: now,
                defColActsEndIsAllDay.name: 0,
                defColCreatedAt.name: zeroDate,
              },
            );
          }
        }
      });

      testWidgets("Show chart.", (widgetTester) async {
        widgetTester.ignoreMockMethodCallHandler(
            MethodChannelMock.flutterLocalNotifications);

        await widgetTester.show(insertedMemName);

        expect(find.byType(LineChartWrapper), findsOneWidget);
      });

      testWidgets("Show statistics.", (widgetTester) async {
        await widgetTester.show(insertedMemName);

        final texts = widgetTester.widgetList<Text>(find.byType(Text));
        expect(texts.elementAt(0).data, equals("Min : "));
        expect(texts.elementAt(2).data, equals("Max : "));
        expect(texts.elementAt(4).data, equals("Avg : "));
      });

      group("Time period", () {
        testWidgets("Show.", (widgetTester) async {
          await widgetTester.show(insertedMemName);

          await widgetTester.tap(find.byIcon(Icons.more_vert));
          await widgetTester.pumpAndSettle();

          for (var period in Period.values) {
            expect(find.text(period.name), findsOneWidget);
          }
        });

        group("Select", () {
          Period.values
              .where(
            (e) => e != Period.aWeek,
          )
              .forEach((target) {
            testWidgets("${target.name}.", (widgetTester) async {
              await widgetTester.show(insertedMemName);

              await widgetTester.tap(find.byIcon(Icons.more_vert));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.text(target.name));
              await widgetTester.pumpAndSettle(waitSideEffectDuration);

              expect(true, isTrue);
            });
          });
        });
      });

      group("Aggregation type", () {
        testWidgets("Show.", (widgetTester) async {
          await widgetTester.show(insertedMemName);

          await widgetTester.tap(find.byIcon(Icons.more_vert));
          await widgetTester.pumpAndSettle();

          for (var aggregationType in AggregationType.values) {
            expect(find.text(aggregationType.name), findsOneWidget);
          }
        });

        group("Select", () {
          AggregationType.values
              .where(
            (e) => e != AggregationType.count,
          )
              .forEach((target) {
            testWidgets("${target.name}.", (widgetTester) async {
              await widgetTester.show(insertedMemName);

              await widgetTester.tap(find.byIcon(Icons.more_vert));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.text(target.name));
              await widgetTester.pumpAndSettle(waitSideEffectDuration);

              expect(true, isTrue);
            });
          });
        });
      });
    });

extension on WidgetTester {
  Future<void> show(String targetMemName) async {
    await runApplication();
    await pumpAndSettle();
    await tap(find.text(targetMemName));
    await pumpAndSettle();
    await tap(find.byIcon(Icons.show_chart));
    await pumpAndSettle();
  }
}
