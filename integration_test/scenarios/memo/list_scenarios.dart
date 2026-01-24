import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/features/mem_items/mem_items_view.dart';

import '../helpers.dart';

const _scenarioName = "Memo list scenario";

void main() => group(
      _scenarioName,
      () {
        IntegrationTestWidgetsFlutterBinding.ensureInitialized();

        late final DriftDatabaseAccessor dbA;
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });

        const insertedMemNameBase = "$_scenarioName: inserted - mem name";
        const unarchivedMemName = "$insertedMemNameBase - unarchived";
        const archivedMemName = "$insertedMemNameBase - archived";

        final mems = [
          {
            defColMemsName.name: unarchivedMemName,
            defColCreatedAt.name: DateTime.now(),
          },
          {
            defColMemsName.name: archivedMemName,
            defColCreatedAt.name: DateTime.now(),
            defColArchivedAt.name: DateTime.now(),
          },
          ...List.generate(
            20,
            (index) => {
              defColMemsName.name: "$insertedMemNameBase - $index",
              defColCreatedAt.name: DateTime.now(),
            },
          ),
        ];

        setUp(() async {
          await clearAllTestDatabaseRows(databaseDefinition);

          for (var e in mems) {
            await dbA.insert(defTableMems, e);
          }
        });

        group("List", () {
          testWidgets('Show elements.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            [
              unarchivedMemName,
            ].forEachIndexed((index, element) {
              expect(
                widgetTester.widget<Text>(find.byType(Text).at(index + 1)).data,
                element,
                reason: "Index is $index.",
              );
            });
            expect(
              (widgetTester
                      .widget<FloatingActionButton>(
                          find.byType(FloatingActionButton))
                      .child as Icon)
                  .icon,
              Icons.add,
            );
            final iconButtons =
                widgetTester.widgetList<IconButton>(find.byType(IconButton));
            [
              DrawerButtonIcon,
              Icons.search,
              Icons.filter_list,
            ].forEachIndexed((index, expected) {
              final icon = iconButtons.elementAt(index).icon;
              if (icon is Icon) {
                expect(
                  icon.icon,
                  expected,
                  reason: "Index is $index.",
                );
              } else {
                expect(
                  icon.runtimeType,
                  expected,
                  reason: "Index is $index.",
                );
              }
            });
          });

          testWidgets(': Hide & show ShowNewMemFab.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            expect(find.byIcon(Icons.add).hitTestable(), findsOneWidget);

            await widgetTester.drag(
              find.text(mems[5][defColMemsName.name] as String),
              const Offset(0, -100),
            );
            await widgetTester.pumpAndSettle();

            expect(find.byIcon(Icons.add).hitTestable(), findsNothing);

            await widgetTester.drag(
              find.text(mems[5][defColMemsName.name] as String),
              const Offset(0, 100),
            );
            await widgetTester.pumpAndSettle();

            expect(find.byIcon(Icons.add).hitTestable(), findsOneWidget);
          });

          group("Search", () {
            const insertedSearchTargetMemName =
                "$_scenarioName - mem name - search target";

            setUp(() async {
              dbA.insert(defTableMems, {
                defColMemsName.name: insertedSearchTargetMemName,
                defColCreatedAt.name: zeroDate,
              });
            });

            testWidgets("Toggle search mode.", (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(searchIconFinder);
              await widgetTester.pump();

              expect(searchIconFinder, findsOneWidget);
              expect(filterListIconFinder, findsNothing);
              expect(closeIconFinder, findsOneWidget);
              expect(
                widgetTester
                    .widget<TextFormField>(find.byType(TextFormField))
                    .initialValue,
                isEmpty,
              );

              await widgetTester.tap(closeIconFinder);
              await widgetTester.pump();

              expect(searchIconFinder, findsOneWidget);
              expect(filterListIconFinder, findsOneWidget);
              expect(closeIconFinder, findsNothing);
            });

            //   testWidgets('Enter search text.', (widgetTester) async {
            //     await runApplication();
            //     await widgetTester.pumpAndSettle();

            //     await widgetTester.tap(searchIconFinder);
            //     await widgetTester.pump();

            //     await widgetTester.enterText(
            //       find.byType(TextFormField),
            //       "search",
            //     );
            //     await widgetTester.pump();

            //     expect(find.text(unarchivedMemName), findsNothing);
            //     expect(find.text(insertedSearchTargetMemName), findsOneWidget);

            //     await widgetTester.tap(closeIconFinder);
            //     await widgetTester.pump();

            //     expect(find.text(unarchivedMemName), findsOneWidget);
            //   });
          });
        });

        group("Transit", () {
          const insertedMemMemo = "$_scenarioName: inserted - mem memo";
          late int insertedMemId;

          setUp(() async {
            await clearAllTestDatabaseRows(databaseDefinition);

            insertedMemId = await dbA.insert(
              defTableMems,
              {
                defColMemsName.name: insertedMemNameBase,
                defColCreatedAt.name: zeroDate,
              },
            );
            await dbA.insert(
              defTableMemItems,
              {
                defFkMemItemsMemId.name: insertedMemId,
                defColMemItemsType.name: MemItemType.memo.name,
                defColMemItemsValue.name: insertedMemMemo,
                defColCreatedAt.name: zeroDate,
              },
            );
          });

          testWidgets("New.", (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(newMemFabFinder);
            await widgetTester.pumpAndSettle();

            final memName =
                widgetTester.widget<TextFormField>(find.byKey(keyMemName));
            final memMemo =
                widgetTester.widget<TextFormField>(find.byKey(keyMemMemo));

            expect(memName.initialValue, isEmpty);
            expect(memMemo.initialValue, isEmpty);
          });

          //   testWidgets("Saved.", (widgetTester) async {
          //     await runApplication();
          //     await widgetTester.pumpAndSettle();

          //     await widgetTester.tap(find.text(insertedMemNameBase));
          //     await widgetTester.pumpAndSettle();

          //     final memName =
          //         widgetTester.widget<TextFormField>(find.byKey(keyMemName));
          //     final memMemo =
          //         widgetTester.widget<TextFormField>(find.byKey(keyMemMemo));

          //     expect(memName.initialValue, equals(insertedMemNameBase));
          //     expect(memMemo.initialValue, equals(insertedMemMemo));
          //   });
        });

        testWidgets('Filter Archive.', (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();

          expect(find.text(unarchivedMemName), findsOneWidget);
          expect(find.text(archivedMemName), findsNothing);

          await widgetTester.tap(filterListIconFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(showArchiveSwitchFinder);
          await widgetTester.pumpAndSettle(waitSideEffectDuration);

          await widgetTester.tap(showNotArchiveSwitchFinder);
          await widgetTester.pumpAndSettle(waitLongSideEffectDuration);

          expect(find.text(unarchivedMemName), findsNothing);
          expect(find.text(archivedMemName), findsOneWidget);

          await closeMemListFilter(widgetTester);
          await widgetTester.pumpAndSettle(waitSideEffectDuration);

          await widgetTester.tap(filterListIconFinder);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(showArchiveSwitchFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text(unarchivedMemName), findsOneWidget);

          await closeMemListFilter(widgetTester);
          await widgetTester.pumpAndSettle();

          expect(find.text(unarchivedMemName), findsOneWidget);
        });
      },
    );
