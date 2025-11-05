import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/widgets/infinite_scroll.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 0, minute: 0);
}

class _FakeActEntities extends ActEntities {
  final Iterable<SavedActEntity> _initialState;
  final List<SavedActEntity> _upserted = [];
  final List<int> _removed = [];
  int _fetchCallCount = 0;
  int _fetchLatestByMemIdsCallCount = 0;
  int _startActbyCallCount = 0;
  int _pauseByMemIdCallCount = 0;
  int _closeByMemIdCallCount = 0;
  int _finishActbyCallCount = 0;
  int _editCallCount = 0;
  int _removeAsyncCallCount = 0;

  _FakeActEntities([Iterable<SavedActEntity>? initialState])
      : _initialState = initialState ?? [];

  @override
  Iterable<SavedActEntity> build() => _initialState;

  @override
  Future<Iterable<SavedActEntity>> fetch(int memId, Period period) async {
    _fetchCallCount++;
    await Future.microtask(() => upsert(_initialState));
    return _initialState;
  }

  @override
  Future<Iterable<SavedActEntity>> fetchLatestByMemIds(
    Iterable<int> memIds,
  ) async {
    _fetchLatestByMemIdsCallCount++;
    await Future.microtask(() => upsert(_initialState));
    return _initialState;
  }

  @override
  Future<void> startActby(int memId) async {
    _startActbyCallCount++;
    final now = DateTime.now();
    final act = SavedActEntity({
      defPkId.name: 1,
      defFkActsMemId.name: memId,
      defColActsStart.name: now,
      defColActsStartIsAllDay.name: false,
      defColActsEnd.name: null,
      defColActsEndIsAllDay.name: null,
      defColActsPausedAt.name: null,
      defColCreatedAt.name: now,
      defColUpdatedAt.name: now,
      defColArchivedAt.name: null,
    });
    upsert([act]);
  }

  @override
  Future<void> pauseByMemId(int memId) async {
    _pauseByMemIdCallCount++;
  }

  @override
  Future<void> closeByMemId(int memId) async {
    _closeByMemIdCallCount++;
    final act = state.firstWhereOrNull((e) => e.value.memId == memId);
    if (act != null) {
      remove([act.id]);
    }
  }

  @override
  Future<void> finishActby(int memId) async {
    _finishActbyCallCount++;
    final now = DateTime.now();
    final act = SavedActEntity({
      defPkId.name: 1,
      defFkActsMemId.name: memId,
      defColActsStart.name: now,
      defColActsStartIsAllDay.name: false,
      defColActsEnd.name: now,
      defColActsEndIsAllDay.name: false,
      defColActsPausedAt.name: null,
      defColCreatedAt.name: now,
      defColUpdatedAt.name: now,
      defColArchivedAt.name: null,
    });
    upsert([act]);
  }

  @override
  Future<void> edit(SavedActEntity act) async {
    _editCallCount++;
    upsert([act]);
  }

  @override
  Future<Iterable<SavedActEntity>> removeAsync(Iterable<int> ids) async {
    _removeAsyncCallCount++;
    _removed.addAll(ids);
    return remove(ids);
  }

  List<SavedActEntity> get upserted => _upserted;
  List<int> get removed => _removed;
  int get fetchCallCount => _fetchCallCount;
  int get fetchLatestByMemIdsCallCount => _fetchLatestByMemIdsCallCount;
  int get startActbyCallCount => _startActbyCallCount;
  int get pauseByMemIdCallCount => _pauseByMemIdCallCount;
  int get closeByMemIdCallCount => _closeByMemIdCallCount;
  int get finishActbyCallCount => _finishActbyCallCount;
  int get editCallCount => _editCallCount;
  int get removeAsyncCallCount => _removeAsyncCallCount;
}

void main() {
  setUpAll(() {
    DatabaseFactory.onTest = true;
    sqflite_ffi.sqfliteFfiInit();
  });

  tearDownAll(() {
    DatabaseFactory.onTest = false;
  });

  group('ActEntities', () {
    test('build returns empty list', () {
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final entities = container.read(actEntitiesProvider);
      expect(entities, isEmpty);
    });

    test('fetch calls repository and upserts results', () async {
      final container = ProviderContainer(
        overrides: [
          preferenceProvider(startOfDayKey)
              .overrideWith(() => _FakePreference()),
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      final result = await notifier.fetch(1, Period.aDay);
      expect(result, isA<Iterable<SavedActEntity>>());
    });

    test('fetchLatestByMemIds calls service and upserts results', () async {
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      final result = await notifier.fetchLatestByMemIds([1, 2]);
      expect(result, isA<Iterable<SavedActEntity>>());
    });

    test('startActby calls client and upserts result', () async {
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      await notifier.startActby(1);
      expect(container.read(actEntitiesProvider), isNotEmpty);
    });

    test('pauseByMemId calls client and upserts results', () async {
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      await notifier.pauseByMemId(1);
      expect(
          container.read(actEntitiesProvider), isA<Iterable<SavedActEntity>>());
    });

    test('closeByMemId calls client and removes result if closed', () async {
      final now = DateTime.now();
      final act = SavedActEntity({
        defPkId.name: 1,
        defFkActsMemId.name: 1,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: null,
        defColActsEndIsAllDay.name: null,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities([act])),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      try {
        await notifier.closeByMemId(1);
        expect(container.read(actEntitiesProvider),
            isA<Iterable<SavedActEntity>>());
      } catch (e) {
        expect(e, isA<StateError>());
      }
    });

    test('finishActby calls client and upserts result', () async {
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      await notifier.finishActby(1);
      expect(container.read(actEntitiesProvider), isNotEmpty);
    });

    test('edit calls client and upserts result', () async {
      final now = DateTime.now();
      final act = SavedActEntity({
        defPkId.name: 1,
        defFkActsMemId.name: 1,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: null,
        defColActsEndIsAllDay.name: null,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      await notifier.edit(act);
      expect(
          container.read(actEntitiesProvider), isA<Iterable<SavedActEntity>>());
    });

    test('removeAsync calls client and removes results', () async {
      final now = DateTime.now();
      final act1 = SavedActEntity({
        defPkId.name: 1,
        defFkActsMemId.name: 1,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: null,
        defColActsEndIsAllDay.name: null,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });
      final act2 = SavedActEntity({
        defPkId.name: 2,
        defFkActsMemId.name: 1,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: null,
        defColActsEndIsAllDay.name: null,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider
              .overrideWith(() => _FakeActEntities([act1, act2])),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      try {
        final result = await notifier.removeAsync([1]);
        expect(result, isA<Iterable<SavedActEntity>>());
        expect(result.length, 1);
      } catch (e) {
        expect(e, isA<StateError>());
      }
    });
  });

  group('loadActList', () {
    test('loads act list for memId and period', () async {
      final container = ProviderContainer(
        overrides: [
          preferenceProvider(startOfDayKey)
              .overrideWith(() => _FakePreference()),
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(loadActListProvider(1, Period.aDay).future);
      expect(
          container.read(actEntitiesProvider), isA<Iterable<SavedActEntity>>());
    });
  });

  group('actList', () {
    test('returns empty list when memId is null', () {
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      container.read(isUpdating(null).notifier).updatedBy(true);

      final list = container.read(actListProvider(null));

      expect(list, isEmpty);
    });

    test('returns filtered and sorted acts for memId', () async {
      final now = DateTime.now();
      final act1 = SavedActEntity({
        defPkId.name: 1,
        defFkActsMemId.name: 1,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: now.add(const Duration(hours: 1)),
        defColActsEndIsAllDay.name: false,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });
      final act2 = SavedActEntity({
        defPkId.name: 2,
        defFkActsMemId.name: 2,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: now.add(const Duration(hours: 1)),
        defColActsEndIsAllDay.name: false,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider
              .overrideWith(() => _FakeActEntities([act1, act2])),
        ],
      );
      addTearDown(container.dispose);

      container.read(isUpdating(1).notifier).updatedBy(true);

      final list = container.read(actListProvider(1));

      expect(list.length, 1);
      expect(list.first.value.memId, 1);
    });

    test('filters out acts without period', () {
      final now = DateTime.now();
      final act1 = SavedActEntity({
        defPkId.name: 1,
        defFkActsMemId.name: 1,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: now.add(const Duration(hours: 1)),
        defColActsEndIsAllDay.name: false,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });
      final act2 = SavedActEntity({
        defPkId.name: 2,
        defFkActsMemId.name: 1,
        defColActsStart.name: null,
        defColActsStartIsAllDay.name: null,
        defColActsEnd.name: null,
        defColActsEndIsAllDay.name: null,
        defColActsPausedAt.name: now,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider
              .overrideWith(() => _FakeActEntities([act1, act2])),
        ],
      );
      addTearDown(container.dispose);

      container.read(isUpdating(1).notifier).updatedBy(true);

      final list = container.read(actListProvider(1));

      expect(list.length, 1);
      expect(list.first.id, 1);
    });

    test('sorts acts by period descending', () {
      final now = DateTime.now();
      final act1 = SavedActEntity({
        defPkId.name: 1,
        defFkActsMemId.name: 1,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: now.add(const Duration(hours: 1)),
        defColActsEndIsAllDay.name: false,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });
      final act2 = SavedActEntity({
        defPkId.name: 2,
        defFkActsMemId.name: 1,
        defColActsStart.name: now.add(const Duration(hours: 2)),
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: now.add(const Duration(hours: 3)),
        defColActsEndIsAllDay.name: false,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider
              .overrideWith(() => _FakeActEntities([act1, act2])),
        ],
      );
      addTearDown(container.dispose);

      container.read(isUpdating(1).notifier).updatedBy(true);

      final list = container.read(actListProvider(1));

      expect(list.length, 2);
      expect(list.first.id, 2);
      expect(list.last.id, 1);
    });
  });

  group('latestActsByMem', () {
    test('returns map of memId to latest act', () {
      final now = DateTime.now();
      final act1 = SavedActEntity({
        defPkId.name: 1,
        defFkActsMemId.name: 1,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: null,
        defColActsEndIsAllDay.name: null,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });
      final act2 = SavedActEntity({
        defPkId.name: 2,
        defFkActsMemId.name: 2,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: null,
        defColActsEndIsAllDay.name: null,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider
              .overrideWith(() => _FakeActEntities([act1, act2])),
        ],
      );
      addTearDown(container.dispose);

      final latestActs = container.read(latestActsByMemProvider);

      expect(latestActs, isNotNull);
      expect(latestActs![1], isNotNull);
      expect(latestActs[2], isNotNull);
    });

    test('returns null when no acts', () {
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final latestActs = container.read(latestActsByMemProvider);

      expect(latestActs, isEmpty);
    });

    test('returns latest act when multiple acts for same memId', () {
      final now = DateTime.now();
      final act1 = SavedActEntity({
        defPkId.name: 1,
        defFkActsMemId.name: 1,
        defColActsStart.name: now,
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: null,
        defColActsEndIsAllDay.name: null,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });
      final act2 = SavedActEntity({
        defPkId.name: 2,
        defFkActsMemId.name: 1,
        defColActsStart.name: now.add(const Duration(hours: 1)),
        defColActsStartIsAllDay.name: false,
        defColActsEnd.name: null,
        defColActsEndIsAllDay.name: null,
        defColActsPausedAt.name: null,
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider
              .overrideWith(() => _FakeActEntities([act1, act2])),
        ],
      );
      addTearDown(container.dispose);

      final latestActs = container.read(latestActsByMemProvider);

      expect(latestActs, isNotNull);
      expect(latestActs![1]?.memId, 1);
    });
  });
}
