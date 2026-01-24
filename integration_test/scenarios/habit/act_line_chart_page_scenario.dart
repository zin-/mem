import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';

import '../helpers.dart';

const _name = "ActLineChartPage scenario";
// const _pumpAndSettleDuration = Duration(seconds: 2);

void main() => group(_name, () {
      const insertedMemName = '$_name: inserted mem - name';

      late final DriftDatabaseAccessor dbA;
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
        await clearAllTestDatabaseRows(databaseDefinition);
        await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: insertedMemName,
            defColCreatedAt.name: zeroDate,
          },
        );

        final now = DateTime.now();
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        final startDate = DateTime(lastMonthYear, lastMonth, 28);

        await dbA.insert(
          defTableActs,
          {
            defFkActsMemId.name: insertedMemId,
            defColActsStart.name: startDate,
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

      // testWidgets("Show chart.", (widgetTester) async {
      //   widgetTester.ignoreMockMethodCallHandler(
      //       MethodChannelMock.flutterLocalNotifications);

      //   await widgetTester.show(insertedMemName);

      //   expect(find.byType(LineChartWrapper), findsOneWidget);
      // });

      // group("Time period", () {
      //   // testWidgets("[flaky]Show.", (widgetTester) async {
      //   //   await widgetTester.show(insertedMemName);

      //   //   await widgetTester.tap(find.byIcon(Icons.more_vert));
      //   //   await widgetTester.pumpAndSettle(_pumpAndSettleDuration);

      //   //   for (var period in Period.values) {
      //   //     expect(find.text(period.name), findsOneWidget);
      //   //   }
      //   // });

      //   // group("Select", () {
      //   //   Period.values
      //   //       .where(
      //   //     (e) => e != Period.aWeek,
      //   //   )
      //   //       .forEach((target) {
      //   //     testWidgets("${target.name}.", (widgetTester) async {
      //   //       await widgetTester.show(insertedMemName);

      //   //       await widgetTester.tap(find.byIcon(Icons.more_vert));
      //   //       await widgetTester.pumpAndSettle(_pumpAndSettleDuration);

      //   //       await widgetTester.tap(find.text(target.name));
      //   //       await widgetTester.pumpAndSettle(_pumpAndSettleDuration);

      //   //       expect(true, isTrue);
      //   //     });
      //   //   });
      //   // });
      // });

      //   group("Aggregation type", () {
      //     // testWidgets("Show.", (widgetTester) async {
      //     //   await widgetTester.show(insertedMemName);

      //     //   await widgetTester.tap(find.byIcon(Icons.more_vert));
      //     //   await widgetTester.pumpAndSettle(_pumpAndSettleDuration);

      //     //   for (var aggregationType in AggregationType.values) {
      //     //     expect(find.text(aggregationType.name), findsOneWidget);
      //     //   }
      //     // });

      //     group("Select", () {
      //       AggregationType.values
      //           .where(
      //         (e) => e != AggregationType.count,
      //       )
      //           .forEach((target) {
      //         testWidgets("${target.name}.", (widgetTester) async {
      //           await widgetTester.show(insertedMemName);

      //           await widgetTester.tap(find.byIcon(Icons.more_vert));
      //           await widgetTester.pumpAndSettle(_pumpAndSettleDuration);

      //           await widgetTester.tap(find.text(target.name));
      //           await widgetTester.pumpAndSettle(_pumpAndSettleDuration);

      //           expect(true, isTrue);
      //         });
      //       });
      //     });
      //   });
    });

// extension on WidgetTester {
//   Future<void> show(String targetMemName) async {
//     await runApplication();
//     await pumpAndSettle(_pumpAndSettleDuration);
//     await tap(find.text(targetMemName));
//     await pumpAndSettle(_pumpAndSettleDuration);
//     await tap(find.byIcon(Icons.show_chart));
//     await pumpAndSettle(_pumpAndSettleDuration);
//   }
// }
