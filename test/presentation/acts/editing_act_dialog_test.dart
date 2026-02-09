import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/acts/list/item/editing_act_dialog.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/framework/date_and_time/date_and_time_text_form_field.dart';

class _FakeActEntities extends ActEntities {
  final Iterable<SavedActEntityV1> _state;
  int editCallCount = 0;
  int removeCallCount = 0;

  _FakeActEntities(this._state);

  @override
  Iterable<SavedActEntityV1> build() => _state;

  @override
  Future<void> edit(SavedActEntityV1 act) async {
    editCallCount++;
  }

  @override
  Future<Iterable<SavedActEntityV1>> removeAsync(Iterable<int> ids) async {
    removeCallCount++;
    return _state.where((e) => !ids.contains(e.id));
  }
}

void main() {
  group('EditingActDialog test', () {
    group('show', () {
      testWidgets('dialog.', (tester) async {
        final targetActEntity = SavedActEntityV1({
          defPkId.name: 1,
          defFkActsMemId.name: 1,
          defColActsStart.name: DateTime.now(),
          defColActsStartIsAllDay.name: false,
          defColActsEnd.name: null,
          defColActsEndIsAllDay.name: null,
          defColActsPausedAt.name: null,
          defColCreatedAt.name: DateTime.now(),
          defColUpdatedAt.name: DateTime.now(),
          defColArchivedAt.name: null,
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              actEntitiesProvider
                  .overrideWith(() => _FakeActEntities([targetActEntity])),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            EditingActDialog(targetActEntity.id),
                      );
                    },
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(DateAndTimePeriodTextFormFields), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
        expect(find.byIcon(Icons.save_alt), findsOneWidget);
      });

      testWidgets('no dialog when target act is not found.', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              actEntitiesProvider.overrideWith(() => _FakeActEntities([])),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditingActDialog(1),
                      );
                    },
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Show Dialog'), findsOneWidget);
      });
    });

    group('action', () {
      testWidgets('change period.', (tester) async {
        final targetActEntity = SavedActEntityV1({
          defPkId.name: 1,
          defFkActsMemId.name: 1,
          defColActsStart.name: DateTime.now(),
          defColActsStartIsAllDay.name: false,
          defColActsEnd.name: DateTime.now(),
          defColActsEndIsAllDay.name: false,
          defColActsPausedAt.name: null,
          defColCreatedAt.name: DateTime.now(),
          defColUpdatedAt.name: DateTime.now(),
          defColArchivedAt.name: null,
        });

        final fakeActEntities = _FakeActEntities([targetActEntity]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditingActDialog(1),
                      );
                    },
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(clearIcon).at(1));
        await tester.pumpAndSettle();

        expect(find.byIcon(clearIcon), findsOneWidget);
      });

      testWidgets('save.', (tester) async {
        final targetActEntity = SavedActEntityV1({
          defPkId.name: 1,
          defFkActsMemId.name: 1,
          defColActsStart.name: DateTime.now(),
          defColActsStartIsAllDay.name: false,
          defColActsEnd.name: null,
          defColActsEndIsAllDay.name: null,
          defColActsPausedAt.name: null,
          defColCreatedAt.name: DateTime.now(),
          defColUpdatedAt.name: DateTime.now(),
          defColArchivedAt.name: null,
        });
        final fakeActEntities = _FakeActEntities([targetActEntity]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditingActDialog(1),
                      );
                    },
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(saveIcon));
        await tester.pumpAndSettle();

        expect(fakeActEntities.editCallCount, 1);
      });

      testWidgets('remove.', (tester) async {
        final targetActEntity = SavedActEntityV1({
          defPkId.name: 1,
          defFkActsMemId.name: 1,
          defColActsStart.name: DateTime.now(),
          defColActsStartIsAllDay.name: false,
          defColActsEnd.name: null,
          defColActsEndIsAllDay.name: null,
          defColActsPausedAt.name: null,
          defColCreatedAt.name: DateTime.now(),
          defColUpdatedAt.name: DateTime.now(),
          defColArchivedAt.name: null,
        });
        final fakeActEntities = _FakeActEntities([targetActEntity]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditingActDialog(1),
                      );
                    },
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(deleteIcon));
        await tester.pumpAndSettle();

        expect(fakeActEntities.removeCallCount, 1);
      });
    });
  });
}
