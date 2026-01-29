import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mem_relations/mem_relation_widget.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/framework/date_and_time/time_text_form_field.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<SavedMemEntityV1> _state;

  _FakeMemEntities(this._state);

  @override
  Iterable<SavedMemEntityV1> build() => _state;
}

class _FakeMemRelationEntitiesByMemId extends MemRelationEntitiesByMemId {
  final Future<Iterable<MemRelationEntity>> Function(int?) _buildFn;
  final List<MemRelationEntity> _upsertedEntities = [];

  _FakeMemRelationEntitiesByMemId(
      Future<Iterable<MemRelationEntity>> Function(int?) buildFn)
      : _buildFn = buildFn;

  @override
  Future<Iterable<MemRelationEntity>> build(int? memId) => _buildFn(memId);

  @override
  Future<Iterable<MemRelationEntity>> upsert(
    Iterable<MemRelationEntity> entities,
  ) async {
    _upsertedEntities.addAll(entities);
    final current = state.value ?? [];
    state = AsyncValue.data([
      ...current.where(
        (e) => e.value.targetMemId != entities.first.value.targetMemId,
      ),
      ...entities,
    ]);
    return state.value ?? [];
  }
}

Widget _buildTestApp(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  group('MemRelationList', () {
    testWidgets('displays relations list when data is available',
        (tester) async {
      const sourceMemId = 1;
      final now = DateTime.now();
      final mem1 = SavedMemEntityV1({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': now,
        'updatedAt': now,
        'archivedAt': null,
      });
      final mem2 = SavedMemEntityV1({
        defPkId.name: 2,
        'name': 'Mem 2',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': now,
        'updatedAt': now,
        'archivedAt': null,
      });

      final relation1 = MemRelationEntity.by(
        sourceMemId,
        1,
        MemRelationType.prePost,
        30,
      );
      final relation2 = MemRelationEntity.by(
        sourceMemId,
        2,
        MemRelationType.prePost,
        60,
      );

      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: sourceMemId),
          overrides: [
            memRelationEntitiesByMemIdProvider(sourceMemId).overrideWith(
              () => _FakeMemRelationEntitiesByMemId(
                (memId) async => [relation1, relation2],
              ),
            ),
            memEntitiesProvider
                .overrideWith(() => _FakeMemEntities([mem1, mem2])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Relations'), findsOneWidget);
      expect(find.text('Mem 1'), findsOneWidget);
      expect(find.text('Mem 2'), findsOneWidget);
      expect(find.byType(TimeTextFormField), findsNWidgets(2));
      expect(find.text('Add Relation'), findsOneWidget);
    });

    testWidgets('displays CircularProgressIndicator when loading',
        (tester) async {
      const sourceMemId = 1;

      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: sourceMemId),
          overrides: [
            memRelationEntitiesByMemIdProvider(sourceMemId).overrideWith(
              () => _FakeMemRelationEntitiesByMemId(
                (memId) async {
                  await Future.delayed(const Duration(milliseconds: 100));
                  return <MemRelationEntity>[];
                },
              ),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([])),
          ],
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('displays error text when error occurs', (tester) async {
      const sourceMemId = 1;

      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: sourceMemId),
          overrides: [
            memRelationEntitiesByMemIdProvider(sourceMemId).overrideWith(
              () => _FakeMemRelationEntitiesByMemId(
                (memId) async => throw Exception('Test error'),
              ),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('displays empty list when no relations', (tester) async {
      const sourceMemId = 1;

      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: sourceMemId),
          overrides: [
            memRelationEntitiesByMemIdProvider(sourceMemId).overrideWith(
              () => _FakeMemRelationEntitiesByMemId(
                (memId) async => <MemRelationEntity>[],
              ),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Relations'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(find.text('Add Relation'), findsOneWidget);
    });

    testWidgets('handles sourceMemId null', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: null),
          overrides: [
            memRelationEntitiesByMemIdProvider(null).overrideWith(
              () => _FakeMemRelationEntitiesByMemId(
                (memId) async => <MemRelationEntity>[],
              ),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Relations'), findsOneWidget);
      expect(find.text('Add Relation'), findsOneWidget);
    });

    testWidgets('opens dialog when Add Relation button is pressed',
        (tester) async {
      const sourceMemId = 1;
      final now = DateTime.now();
      final mem1 = SavedMemEntityV1({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': now,
        'updatedAt': now,
        'archivedAt': null,
      });

      final relation1 = MemRelationEntity.by(
        sourceMemId,
        1,
        MemRelationType.prePost,
        30,
      );

      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: sourceMemId),
          overrides: [
            memRelationEntitiesByMemIdProvider(sourceMemId).overrideWith(
              () => _FakeMemRelationEntitiesByMemId(
                (memId) async => [relation1],
              ),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem1])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Relation').first);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('calls onChanged when value is changed', (tester) async {
      const sourceMemId = 1;
      final now = DateTime.now();
      final mem1 = SavedMemEntityV1({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': now,
        'updatedAt': now,
        'archivedAt': null,
      });

      final relation1 = MemRelationEntity.by(
        sourceMemId,
        1,
        MemRelationType.prePost,
        30,
      );

      final fakeProvider = _FakeMemRelationEntitiesByMemId(
        (memId) async => [relation1],
      );

      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: sourceMemId),
          overrides: [
            memRelationEntitiesByMemIdProvider(sourceMemId).overrideWith(
              () => fakeProvider,
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem1])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TimeTextFormField), findsOneWidget);
      expect(find.text('Mem 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
    });

    testWidgets('displays relations with correct height when more than 3',
        (tester) async {
      const sourceMemId = 1;
      final now = DateTime.now();
      final mems = List.generate(
          4,
          (index) => SavedMemEntityV1({
                defPkId.name: index + 1,
                'name': 'Mem ${index + 1}',
                'doneAt': null,
                'notifyOn': null,
                'notifyAt': null,
                'endOn': null,
                'endAt': null,
                'createdAt': now,
                'updatedAt': now,
                'archivedAt': null,
              }));

      final relations = mems
          .map((mem) => MemRelationEntity.by(
                sourceMemId,
                mem.id,
                MemRelationType.prePost,
                30,
              ))
          .toList();

      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: sourceMemId),
          overrides: [
            memRelationEntitiesByMemIdProvider(sourceMemId).overrideWith(
              () => _FakeMemRelationEntitiesByMemId(
                (memId) async => relations,
              ),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Relations'), findsOneWidget);
      expect(find.byType(TimeTextFormField), findsNWidgets(4));

      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);

      final sizedBox = tester.widget<SizedBox>(sizedBoxes.first);
      expect(sizedBox.height, 180.0);
    });

    testWidgets('displays relations with correct height when 3 or less',
        (tester) async {
      const sourceMemId = 1;
      final now = DateTime.now();
      final mems = List.generate(
          2,
          (index) => SavedMemEntityV1({
                defPkId.name: index + 1,
                'name': 'Mem ${index + 1}',
                'doneAt': null,
                'notifyOn': null,
                'notifyAt': null,
                'endOn': null,
                'endAt': null,
                'createdAt': now,
                'updatedAt': now,
                'archivedAt': null,
              }));

      final relations = mems
          .map((mem) => MemRelationEntity.by(
                sourceMemId,
                mem.id,
                MemRelationType.prePost,
                30,
              ))
          .toList();

      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: sourceMemId),
          overrides: [
            memRelationEntitiesByMemIdProvider(sourceMemId).overrideWith(
              () => _FakeMemRelationEntitiesByMemId(
                (memId) async => relations,
              ),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Relations'), findsOneWidget);
      expect(find.byType(TimeTextFormField), findsNWidgets(2));

      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);

      final sizedBox = tester.widget<SizedBox>(sizedBoxes.first);
      expect(sizedBox.height, 120.0);
    });

    testWidgets('calls onChanged with 0 when value is null', (tester) async {
      const sourceMemId = 1;
      final now = DateTime.now();
      final mem1 = SavedMemEntityV1({
        defPkId.name: 1,
        'name': 'Mem 1',
        'doneAt': null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        'createdAt': now,
        'updatedAt': now,
        'archivedAt': null,
      });

      final relation1 = MemRelationEntity.by(
        sourceMemId,
        1,
        MemRelationType.prePost,
        30,
      );

      final fakeProvider = _FakeMemRelationEntitiesByMemId(
        (memId) async => [relation1],
      );

      await tester.pumpWidget(
        _buildTestApp(
          const MemRelationList(sourceMemId: sourceMemId),
          overrides: [
            memRelationEntitiesByMemIdProvider(sourceMemId).overrideWith(
              () => fakeProvider,
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem1])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TimeTextFormField), findsOneWidget);
      expect(find.text('Mem 1'), findsOneWidget);
    });
  });
}
