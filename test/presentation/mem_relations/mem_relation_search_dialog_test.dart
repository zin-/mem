import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/mem_relations/mem_relation_search_dialog.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<SavedMemEntity> _state;

  _FakeMemEntities(this._state);

  @override
  Iterable<SavedMemEntity> build() => _state;
}

Widget _buildTestApp(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => child,
        ),
      ),
    ),
  );
}

void main() {
  group('MemRelationDialogStateful', () {
    testWidgets('initializes with selectedMemIds', (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });
      final mem2 = SavedMemEntity({
        defPkId.name: 2,
        'name': 'Mem 2',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [1],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider
                .overrideWith(() => _FakeMemEntities([mem1, mem2])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final checkbox1 = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox1.value, true);

      final checkbox2 = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).at(1),
      );
      expect(checkbox2.value, false);
    });

    testWidgets('updates searchText when typing', (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Apple',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });
      final mem2 = SavedMemEntity({
        defPkId.name: 2,
        'name': 'Banana',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider
                .overrideWith(() => _FakeMemEntities([mem1, mem2])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(2));

      await tester.enterText(
        find.byKey(searchMemRelationDialogSearchFieldKey),
        'App',
      );
      await tester.pump();

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('updates selectedMemIds when checkbox is toggled',
        (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem1])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, false);

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      final updatedCheckbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(updatedCheckbox.value, true);
    });

    testWidgets('submits selectedMemIds when add button is pressed',
        (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      List<int>? submittedIds;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [],
                    onSubmit: (ids) => submittedIds = ids,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem1])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      expect(submittedIds, [1]);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('closes dialog when cancel button is pressed', (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem1])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });
  });

  group('MemRelationDialogConsumer', () {
    testWidgets('filters candidates by searchText', (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Apple',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });
      final mem2 = SavedMemEntity({
        defPkId.name: 2,
        'name': 'Banana',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });
      final mem3 = SavedMemEntity({
        defPkId.name: 3,
        'name': 'Cherry',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider
                .overrideWith(() => _FakeMemEntities([mem1, mem2, mem3])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(3));

      await tester.enterText(
        find.byKey(searchMemRelationDialogSearchFieldKey),
        'Ban',
      );
      await tester.pump();

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('includes selected mems even if searchText does not match',
        (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Apple',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });
      final mem2 = SavedMemEntity({
        defPkId.name: 2,
        'name': 'Banana',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [1],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider
                .overrideWith(() => _FakeMemEntities([mem1, mem2])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(searchMemRelationDialogSearchFieldKey),
        'Ban',
      );
      await tester.pump();

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('excludes sourceMemId from candidates', (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });
      final mem2 = SavedMemEntity({
        defPkId.name: 2,
        'name': 'Mem 2',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: 1,
                    selectedMemIds: [],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider
                .overrideWith(() => _FakeMemEntities([mem1, mem2])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Mem 2'), findsOneWidget);
      expect(find.text('Mem 1'), findsNothing);
    });

    testWidgets('shows all candidates when searchText is empty',
        (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });
      final mem2 = SavedMemEntity({
        defPkId.name: 2,
        'name': 'Mem 2',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider
                .overrideWith(() => _FakeMemEntities([mem1, mem2])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });
  });

  group('MemRelationDialog', () {
    testWidgets('displays dialog with title and search field', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Relation'), findsOneWidget);
      expect(
        find.byKey(searchMemRelationDialogSearchFieldKey),
        findsOneWidget,
      );
    });

    testWidgets('displays candidates in list', (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });
      final mem2 = SavedMemEntity({
        defPkId.name: 2,
        'name': 'Mem 2',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider
                .overrideWith(() => _FakeMemEntities([mem1, mem2])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Mem 1'), findsOneWidget);
      expect(find.text('Mem 2'), findsOneWidget);
    });

    testWidgets('toggles checkbox when tapped', (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem1])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      var checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, false);

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, true);

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, false);
    });

    testWidgets('unchecks checkbox when already selected', (tester) async {
      final mem1 = SavedMemEntity({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'archivedAt': null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MemRelationDialogStateful(
                    sourceMemId: null,
                    selectedMemIds: [1],
                    onSubmit: (_) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
          overrides: [
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem1])),
          ],
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      var checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, true);

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, false);
    });
  });
}
