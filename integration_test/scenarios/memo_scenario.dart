import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/values/durations.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testMemoScenario();
}

const scenarioName = 'Memo scenario';

void testMemoScenario() => group(
      ': $scenarioName',
      () {
        const insertedMemName = '$scenarioName - mem name - inserted';
        const insertedMemMemo = '$scenarioName - mem memo - inserted';
        late final DatabaseAccessor dbA;

        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });
        setUp(() async {
          await clearAllTestDatabaseRows(databaseDefinition);

          final insertedMemId = await dbA.insert(
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

        group(": List", () {
          testWidgets(
            ': Show elements.',
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              [
                insertedMemName,
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
                "$scenarioName - mem name - search target";

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
                insertedMemName,
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

              expect(find.text(insertedMemName), findsNothing);
              expect(find.text(insertedSearchTargetMemName), findsOneWidget);

              await widgetTester.tap(closeIconFinder);
              await widgetTester.pump();

              expect(find.text(insertedMemName), findsOneWidget);
              expect(find.text(insertedSearchTargetMemName), findsOneWidget);
            });
          });
        });

        group(': Save', () {
          testWidgets(
            ': Create.',
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(newMemFabFinder);
              await widgetTester.pumpAndSettle();

              expect(find.text(insertedMemName), findsNothing);
              expect(find.text(insertedMemMemo), findsNothing);
              const enteringMemNameText =
                  '$scenarioName: Save: Create - mem name - entering';
              await widgetTester.enterText(
                memNameOnDetailPageFinder,
                enteringMemNameText,
              );
              await widgetTester.pumpAndSettle();

              expect(find.text(enteringMemNameText), findsOneWidget);
              const enteringMemMemoText =
                  '$scenarioName: Save: Create - mem memo - entering';
              await widgetTester.enterText(
                memMemoOnDetailPageFinder,
                enteringMemMemoText,
              );
              await widgetTester.pumpAndSettle();

              expect(find.text(enteringMemMemoText), findsOneWidget);
              await widgetTester.tap(saveMemFabFinder);
              await widgetTester.pump(defaultTransitionDuration);

              const saveSuccessText = 'Save success. $enteringMemNameText';
              expect(
                find.text(saveSuccessText),
                findsOneWidget,
              );
              await widgetTester.pumpAndSettle(defaultDismissDuration);

              expect(find.text(saveSuccessText), findsNothing);
              await widgetTester.pageBack();
              await widgetTester.pumpAndSettle();

              expect(find.text(insertedMemName), findsOneWidget);
              expect(find.text(enteringMemNameText), findsOneWidget);
              expect(find.text(enteringMemMemoText), findsNothing);
              await widgetTester.tap(find.text(enteringMemNameText));
              await widgetTester.pumpAndSettle();

              expect(find.text(insertedMemName), findsNothing);
              expect(find.text(enteringMemNameText), findsOneWidget);
              expect(find.text(enteringMemMemoText), findsOneWidget);
            },
          );

          group(": Update", () {
            testWidgets(
              ': mem name.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(memNameOnDetailPageFinder);
                await widgetTester.pump(waitShowSoftwareKeyboardDuration);

                const enteringMemNameText =
                    '$scenarioName: Save: Update - mem name - entering';
                await widgetTester.enterText(
                  memNameOnDetailPageFinder,
                  enteringMemNameText,
                );
                await widgetTester.pumpAndSettle();
                expect(find.text(enteringMemNameText), findsOneWidget);

                await widgetTester.tap(saveMemFabFinder);
                await widgetTester.pumpAndSettle();
                const saveSuccessText = 'Save success. $enteringMemNameText';
                expect(
                  find.text(saveSuccessText),
                  findsOneWidget,
                );

                await widgetTester.pumpAndSettle(defaultDismissDuration);
                expect(
                  find.text(saveSuccessText),
                  findsNothing,
                );

                await widgetTester.pageBack();
                await widgetTester.pumpAndSettle();
                expect(find.text(insertedMemName), findsNothing);
                expect(find.text(enteringMemNameText), findsOneWidget);

                await widgetTester.tap(find.text(enteringMemNameText));
                await widgetTester.pumpAndSettle();
                expect(find.text(insertedMemName), findsNothing);
                expect(find.text(enteringMemNameText), findsOneWidget);
              },
            );

            testWidgets(
              ': mem memo.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(memMemoOnDetailPageFinder);
                await widgetTester.pump(waitShowSoftwareKeyboardDuration);

                const enteringMemMemoText =
                    '$scenarioName: Save: Update - mem memo - entering';
                await widgetTester.enterText(
                  memMemoOnDetailPageFinder,
                  enteringMemMemoText,
                );
                await widgetTester.pumpAndSettle();
                expect(find.text(enteringMemMemoText), findsOneWidget);

                await widgetTester.tap(saveMemFabFinder);
                await widgetTester.pumpAndSettle();
                const saveSuccessText = 'Save success. $insertedMemName';
                expect(
                  find.text(saveSuccessText),
                  findsOneWidget,
                );

                await widgetTester.pageBack();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();
                expect(find.text(insertedMemName), findsOneWidget);
                expect(find.text(enteringMemMemoText), findsOneWidget);
              },
            );
          });

          group(': Archive', () {
            const unarchivedMemName = '$scenarioName: V2: Archive: unarchived';
            const archivedMemName = 'Memo scenario: V2: Archive: archived';

            setUp(() async {
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

            testWidgets(
              ': archive & unarchive.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                expect(find.text(unarchivedMemName), findsOneWidget);
                expect(find.text(archivedMemName), findsNothing);

                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byIcon(Icons.more_vert));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byIcon(Icons.archive));
                await widgetTester.pumpAndSettle();

                expect(
                  find.text(insertedMemName),
                  findsNothing,
                );
                await widgetTester.tap(filterListIconFinder);
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(showArchiveSwitchFinder);
                await widgetTester.pumpAndSettle();

                await closeMemListFilter(widgetTester);
                await widgetTester.pumpAndSettle(defaultTransitionDuration);

                expect(find.text(unarchivedMemName), findsOneWidget);
                expect(find.text(archivedMemName), findsOneWidget);
                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byIcon(Icons.more_vert));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byIcon(Icons.unarchive));
                await widgetTester.pumpAndSettle();

                await widgetTester.pageBack();
                await widgetTester.pumpAndSettle();

                expect(find.text(unarchivedMemName), findsOneWidget);
                expect(find.text(archivedMemName), findsOneWidget);
                await widgetTester.tap(filterListIconFinder);
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(showNotArchiveSwitchFinder);
                await widgetTester.pumpAndSettle();

                await closeMemListFilter(widgetTester);
                await widgetTester.pumpAndSettle(defaultTransitionDuration);

                expect(find.text(insertedMemName), findsNothing);
                expect(find.text(unarchivedMemName), findsNothing);
                expect(find.text(archivedMemName), findsOneWidget);
              },
            );
          });
        });

        testWidgets(
          ': Remove & undo.',
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            await widgetTester.tap(find.byIcon(Icons.more_vert));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.delete));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text('Cancel'));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.more_vert));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.delete));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text('OK'));
            await Future.delayed(waitSideEffectDuration);
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            expect(
              find.text('Remove success. $insertedMemName'),
              findsOneWidget,
            );
            expect(find.text(insertedMemName), findsNothing);
            await widgetTester.tap(find.byIcon(Icons.filter_list));
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            await widgetTester.tap(find.byType(Switch).at(1));
            await widgetTester.tap(find.byType(Switch).at(3));
            await widgetTester.pump();

            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            expect(find.text(insertedMemName), findsNothing);
            expect(
              find.text('Remove success. $insertedMemName'),
              findsOneWidget,
            );
            await widgetTester.tap(find.text('Undo'));
            await widgetTester.pumpAndSettle();

            expect(
              find.text('Remove success. $insertedMemName'),
              findsNothing,
            );
            expect(
              find.text('Undo success. $insertedMemName'),
              findsOneWidget,
            );
            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            expect(find.text(insertedMemName), findsOneWidget);
            expect(find.text(insertedMemMemo), findsOneWidget);
          },
        );

        group(': MemItemsView', () {
          setUp(() async {
            await dbA.delete(defTableMemItems);
          });

          testWidgets(': save twice on create.', (widgetTester) async {
            await runApplication();
            await widgetTester.pump();

            await widgetTester.tap(newMemFabFinder);
            await widgetTester.pumpAndSettle();

            const enteringMemNameText =
                '$scenarioName: MemItemsView: save twice on create - mem name - entering';
            await widgetTester.enterText(
              memNameOnDetailPageFinder,
              enteringMemNameText,
            );
            const enteringMemMemoText =
                '$scenarioName: MemItemsView: save twice on create - mem memo - entering';
            const enteringMemMemoText1 = '$enteringMemMemoText - 1';
            await widgetTester.enterText(
              memMemoOnDetailPageFinder,
              enteringMemMemoText1,
            );
            await widgetTester.tap(saveMemFabFinder);
            await widgetTester.pumpAndSettle(defaultDismissDuration);

            await widgetTester.tap(find.text(enteringMemMemoText1));
            await widgetTester.pump(defaultTransitionDuration);

            const enteringMemMemoText2 = '$enteringMemMemoText - 2';
            await widgetTester.enterText(
              memMemoOnDetailPageFinder,
              enteringMemMemoText2,
            );
            await widgetTester.pump(defaultTransitionDuration);

            expect(find.text(enteringMemMemoText1), findsNothing);
            expect(find.text(enteringMemMemoText2), findsOneWidget);
            await widgetTester.tap(saveMemFabFinder);
            await widgetTester.pumpAndSettle(defaultDismissDuration);

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            await widgetTester.tap(find.text(enteringMemNameText));
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            expect(find.text(enteringMemMemoText1), findsNothing);
            expect(find.text(enteringMemMemoText2), findsOneWidget);

            final mem = (await dbA.select(
              defTableMems,
              where: '${defColMemsName.name} = ?',
              whereArgs: [enteringMemNameText],
            ))
                .single;
            final memItems = await dbA.select(
              defTableMemItems,
              where: '${defFkMemItemsMemId.name} = ?',
              whereArgs: [mem['id']],
            );
            expect(memItems.length, 1);
            expect(
              memItems.single[defColMemItemsValue.name],
              enteringMemMemoText2,
            );
          });
        });
      },
    );
