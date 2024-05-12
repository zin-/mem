import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/mems/detail/mem_items_view.dart';

import '../helpers.dart';

const _scenarioName = "Memo list scenario";

void main() => group(
      _scenarioName,
      () {
        IntegrationTestWidgetsFlutterBinding.ensureInitialized();

        late final DatabaseAccessor dbA;
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });

        const insertedMemName = "$_scenarioName: inserted - mem name";
        const unarchivedMemName = "$insertedMemName - unarchived";
        const archivedMemName = "$insertedMemName - archived";

        setUp(() async {
          await clearAllTestDatabaseRows(databaseDefinition);

          await dbA.insert(
            defTableMems,
            {
              defColMemsName.name: unarchivedMemName,
              defColCreatedAt.name: DateTime.now(),
            },
          );
          await dbA.insert(
            defTableMems,
            {
              defColMemsName.name: archivedMemName,
              defColCreatedAt.name: DateTime.now(),
              defColArchivedAt.name: DateTime.now(),
            },
          );
        });

        group(": List", () {
          testWidgets(
            ': Show elements.',
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              [
                unarchivedMemName,
              ].forEachIndexed((index, element) {
                expect(
                  widgetTester.widget<Text>(find.byType(Text).at(index)).data,
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
            },
          );

          group(": Search", () {
            const insertedSearchTargetMemName =
                "$_scenarioName - mem name - search target";

            setUp(() async {
              dbA.insert(defTableMems, {
                defColMemsName.name: insertedSearchTargetMemName,
                defColCreatedAt.name: zeroDate,
              });
            });

            testWidgets(": toggle search mode.", (widgetTester) async {
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

            testWidgets(": enter search text.", (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(searchIconFinder);
              await widgetTester.pump();

              [
                unarchivedMemName,
                insertedSearchTargetMemName,
              ].forEachIndexed((index, element) {
                expect(
                  widgetTester.widget<Text>(find.byType(Text).at(index)).data,
                  element,
                  reason: "Index is $index.",
                );
              });

              await widgetTester.enterText(
                find.byType(TextFormField),
                "search",
              );
              await widgetTester.pump();

              expect(find.text(unarchivedMemName), findsNothing);
              expect(find.text(insertedSearchTargetMemName), findsOneWidget);

              await widgetTester.tap(closeIconFinder);
              await widgetTester.pump();

              expect(find.text(unarchivedMemName), findsOneWidget);
              expect(find.text(insertedSearchTargetMemName), findsOneWidget);
            });
          });
        });

        group(
          ": Transit",
          () {
            const insertedMemMemo = "$_scenarioName: inserted - mem memo";
            late int insertedMemId;

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
                defTableMemItems,
                {
                  defFkMemItemsMemId.name: insertedMemId,
                  defColMemItemsType.name: MemItemType.memo.name,
                  defColMemItemsValue.name: insertedMemMemo,
                  defColCreatedAt.name: zeroDate,
                },
              );
            });

            testWidgets(
              ": new.",
              (widgetTester) async {
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
              },
            );

            testWidgets(
              ": saved.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                final memName =
                    widgetTester.widget<TextFormField>(find.byKey(keyMemName));
                final memMemo =
                    widgetTester.widget<TextFormField>(find.byKey(keyMemMemo));

                expect(memName.initialValue, equals(insertedMemName));
                expect(memMemo.initialValue, equals(insertedMemMemo));
              },
            );
          },
        );

        testWidgets(
          ": Filter: Archive",
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            expect(find.text(unarchivedMemName), findsOneWidget);
            expect(find.text(archivedMemName), findsNothing);

            await widgetTester.tap(filterListIconFinder);
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(showArchiveSwitchFinder);
            await widgetTester.pumpAndSettle();

            expect(find.text(unarchivedMemName), findsOneWidget);
            expect(find.text(archivedMemName), findsOneWidget);

            await widgetTester.tap(showNotArchiveSwitchFinder);
            await widgetTester.pumpAndSettle();

            expect(find.text(unarchivedMemName), findsNothing);
            expect(find.text(archivedMemName), findsOneWidget);

            await widgetTester.tap(showArchiveSwitchFinder);
            await widgetTester.pumpAndSettle();

            expect(find.text(unarchivedMemName), findsOneWidget);
            expect(find.text(archivedMemName), findsOneWidget);

            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle();

            expect(find.text(unarchivedMemName), findsOneWidget);
            expect(find.text(archivedMemName), findsOneWidget);
          },
        );
      },
    );
