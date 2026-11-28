import 'dart:async';
import '../../entity_factories.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/databases/database.dart' hide Act, Target;
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/widgets/infinite_scroll.dart';

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 0, minute: 0);
}

class _FakeActEntities extends ActEntities {
  final Iterable<SavedActEntityV1> _initialState;
  int? _lastFetchOffset;
  int _resumeActByCallCount = 0;
  int _skipActByCallCount = 0;

  _FakeActEntities([Iterable<SavedActEntityV1>? initialState])
      : _initialState = initialState ?? [];

  @override
  Iterable<SavedActEntityV1> build() => _initialState;

  @override
  Future<Iterable<SavedActEntityV1>> fetch(
    int memId,
    Period period, {
    int offset = 0,
  }) async {
    _lastFetchOffset = offset;
    await Future.microtask(() => upsert(_initialState));
    return _initialState;
  }

  @override
  Future<void> startActby(int memId) async {
    final now = DateTime.now();
    final act = savedAct(
        id: 1,
        memId: memId,
        start: now,
        startIsAllDay: false,
        createdAt: now,
        updatedAt: now);
    upsert([act]);
  }

  @override
  Future<void> resumeActBy(int memId) async {
    _resumeActByCallCount++;
    final now = DateTime.now();
    final act = savedAct(
        id: 2,
        memId: memId,
        start: now,
        startIsAllDay: false,
        createdAt: now,
        updatedAt: now);
    upsert([act]);
  }

  @override
  Future<void> pauseByMemId(int memId) async {}

  @override
  Future<void> unpauseByMemId(int memId) async {
    final act = state.firstWhereOrNull((e) => e.value.memId == memId);
    if (act != null) {
      remove([act.id]);
    }
  }

  @override
  Future<void> finishActby(int memId) async {
    final now = DateTime.now();
    final act = savedAct(
        id: 1,
        memId: memId,
        start: now,
        startIsAllDay: false,
        end: now,
        endIsAllDay: false,
        createdAt: now,
        updatedAt: now);
    upsert([act]);
  }

  @override
  Future<void> skipActBy(int memId) async {
    _skipActByCallCount++;
    final now = DateTime.now();
    final act = savedAct(
        id: 3,
        memId: memId,
        start: now,
        startIsAllDay: false,
        end: now,
        endIsAllDay: false,
        createdAt: now,
        updatedAt: now,
        actKind: ActKind.skipped);
    upsert([act]);
  }

  @override
  Future<void> edit(SavedActEntityV1 act) async {
    upsert([act]);
  }

  @override
  Future<Iterable<SavedActEntityV1>> removeAsync(Iterable<int> ids) async =>
      remove(ids);
}

// 時間。終了のある act にするため。ページ順は start の新しい順で、この長さは使わない
const _closedActLength = Duration(hours: 1);

Future<AppDatabase> _openMemoryDatabase() async {
  final db = AppDatabase.memory();
  addTearDown(() async {
    await db.close();
    DriftDatabaseAccessor.reset();
    Singleton.reset<ActQueryService>();
    ActsClient.resetSingleton();
  });
  await Migrator(db).createAll();
  DriftDatabaseAccessor.reset();
  Singleton.reset<ActQueryService>();
  ActsClient.resetSingleton();
  Singleton.override<DriftDatabaseAccessor>(
    DriftDatabaseAccessor.withDatabase(db),
  );
  return db;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setOnTest(true);
  });

  tearDownAll(() {
    setOnTest(false);
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
      expect(result, isA<Iterable<SavedActEntityV1>>());
    });

    test('fetch returns acts inside the offset week only', () async {
      final db = AppDatabase.memory();
      await Migrator(db).createAll();
      DriftDatabaseAccessor.reset();
      Singleton.reset<ActQueryService>();
      Singleton.override<DriftDatabaseAccessor>(
        DriftDatabaseAccessor.withDatabase(db),
      );
      addTearDown(() async {
        await db.close();
        DriftDatabaseAccessor.reset();
        Singleton.reset<ActQueryService>();
      });

      final container = ProviderContainer(
        overrides: [
          preferenceProvider(startOfDayKey)
              .overrideWith(() => _FakePreference()),
        ],
      );
      addTearDown(container.dispose);

      const offset = -1;
      final window = Period.aWeek.toPeriod(
        DateAndTime.now(),
        container.read(preferenceProvider(startOfDayKey)),
        offset: offset,
      )!;
      final now = DateTime.now();
      final mem = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );

      Future<int> insertAct(DateTime start) => db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: mem.id,
              createdAt: now,
              start: Value(start),
              end: Value(start.add(const Duration(hours: 1))),
            ),
          );

      final insideId = await insertAct(window.start);
      await insertAct(window.start.subtract(const Duration(hours: 1)));
      await insertAct(now);

      final result = await container
          .read(actEntitiesProvider.notifier)
          .fetch(mem.id, Period.aWeek, offset: offset);

      expect(result.map((act) => act.id), [insideId]);
      expect(
        container.read(actEntitiesProvider).map((act) => act.id),
        [insideId],
      );
    });

    test('reloadShown puts the only act in state on the first page', () async {
      final db = await _openMemoryDatabase();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // ページ。currentPage の初期値。act が1件なら maxPage もこのページになる
      const firstPage = 1;
      final now = DateTime.now();
      final mem = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );
      final actId = await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: mem.id,
              createdAt: now,
              start: Value(now),
              end: Value(now.add(_closedActLength)),
            ),
          );

      container.listen(isLoading(mem.id), (_, __) {});
      container.listen(isUpdating(mem.id), (_, __) {});
      expect(container.read(currentPage(mem.id)), firstPage);

      await container.read(actEntitiesProvider.notifier).reloadShown(mem.id);

      expect(
        container.read(actEntitiesProvider).map((act) => act.id),
        [actId],
      );
      expect(container.read(isLoading(mem.id)), isFalse);
      expect(container.read(isUpdating(mem.id)), isTrue);
      expect(container.read(maxPage(mem.id)), firstPage);
    });

    test(
      'reloadShown puts the newest and oldest acts in state when the second page is shown',
      () async {
        final db = await _openMemoryDatabase();
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // 件。ActsClient.fetch の1ページ。1件多いと一番古い act が次のページに入る
        const actsPerPage = 50;
        final actCount = actsPerPage + 1;
        final secondPage = (actCount / actsPerPage).ceil();
        final now = DateTime.now();
        final mem = await db.into(db.mems).insertReturning(
              MemsCompanion.insert(name: 'm', createdAt: now),
            );

        final ids = <int>[];
        for (var minute = 0; minute < actCount; minute++) {
          final start = now.add(Duration(minutes: minute));
          ids.add(
            await db.into(db.acts).insert(
                  ActsCompanion.insert(
                    memId: mem.id,
                    createdAt: now,
                    start: Value(start),
                    end: Value(start.add(_closedActLength)),
                  ),
                ),
          );
        }

        container.read(currentPage(mem.id).notifier).updatedBy(secondPage);

        await container.read(actEntitiesProvider.notifier).reloadShown(mem.id);

        final oldestId = ids.first;
        final newestId = ids.last;
        expect(
          container.read(actEntitiesProvider).map((act) => act.id),
          containsAll([newestId, oldestId]),
        );
        expect(container.read(maxPage(mem.id)), secondPage);
      },
    );

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

    test('resumeActBy calls client and upserts result', () async {
      final fake = _FakeActEntities();
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => fake),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      await notifier.resumeActBy(1);
      expect(container.read(actEntitiesProvider), isNotEmpty);
      expect(fake._resumeActByCallCount, 1);
    });

    test('upsert after listeners are gone does not throw', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(actEntitiesProvider, (_, __) {});
      final notifier = container.read(actEntitiesProvider.notifier);
      subscription.close();

      await Future<void>.delayed(Duration.zero);

      expect(() => notifier.upsert(const []), returnsNormally);
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
      expect(container.read(actEntitiesProvider),
          isA<Iterable<SavedActEntityV1>>());
    });

    test('unpauseByMemId calls client and removes result if unpaused',
        () async {
      final now = DateTime.now();
      final act = savedAct(
          id: 1,
          memId: 1,
          start: now,
          startIsAllDay: false,
          createdAt: now,
          updatedAt: now);

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities([act])),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      try {
        await notifier.unpauseByMemId(1);
        expect(container.read(actEntitiesProvider),
            isA<Iterable<SavedActEntityV1>>());
      } catch (e) {
        expect(e, isA<StateError>());
      }
    });

    test('unpauseByMemId does not remove result if unpaused is null', () async {
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      await notifier.unpauseByMemId(1);
      expect(container.read(actEntitiesProvider), isEmpty);
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

    test('skipActBy calls client and upserts skipped act', () async {
      final fake = _FakeActEntities();
      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => fake),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      await notifier.skipActBy(1);

      expect(fake._skipActByCallCount, 1);
      expect(
        container.read(actEntitiesProvider).single.value.actKind,
        ActKind.skipped,
      );
    });

    test('edit calls client and upserts result', () async {
      final now = DateTime.now();
      final act = savedAct(
          id: 1,
          memId: 1,
          start: now,
          startIsAllDay: false,
          createdAt: now,
          updatedAt: now);

      final container = ProviderContainer(
        overrides: [
          actEntitiesProvider.overrideWith(() => _FakeActEntities()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(actEntitiesProvider.notifier);

      await notifier.edit(act);
      expect(container.read(actEntitiesProvider),
          isA<Iterable<SavedActEntityV1>>());
    });

    test('removeAsync calls client and removes results', () async {
      final now = DateTime.now();
      final act1 = savedAct(
          id: 1,
          memId: 1,
          start: now,
          startIsAllDay: false,
          createdAt: now,
          updatedAt: now);
      final act2 = savedAct(
          id: 2,
          memId: 1,
          start: now,
          startIsAllDay: false,
          createdAt: now,
          updatedAt: now);

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
        expect(result, isA<Iterable<SavedActEntityV1>>());
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

      await container.read(loadActListProvider(1, Period.aDay, 0).future);
      expect(container.read(actEntitiesProvider),
          isA<Iterable<SavedActEntityV1>>());
    });

    test('passes offset to fetch', () async {
      final fake = _FakeActEntities();
      final container = ProviderContainer(
        overrides: [
          preferenceProvider(startOfDayKey)
              .overrideWith(() => _FakePreference()),
          actEntitiesProvider.overrideWith(() => fake),
        ],
      );
      addTearDown(container.dispose);

      await container.read(loadActListProvider(1, Period.aWeek, -2).future);
      expect(fake._lastFetchOffset, -2);
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
      final act1 = savedAct(
          id: 1,
          memId: 1,
          start: now,
          startIsAllDay: false,
          end: now.add(const Duration(hours: 1)),
          endIsAllDay: false,
          createdAt: now,
          updatedAt: now);
      final act2 = savedAct(
          id: 2,
          memId: 2,
          start: now,
          startIsAllDay: false,
          end: now.add(const Duration(hours: 1)),
          endIsAllDay: false,
          createdAt: now,
          updatedAt: now);

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
      final act1 = savedAct(
          id: 1,
          memId: 1,
          start: now,
          startIsAllDay: false,
          end: now.add(const Duration(hours: 1)),
          endIsAllDay: false,
          createdAt: now,
          updatedAt: now);
      final act2 = savedAct(
          id: 2, memId: 1, pausedAt: now, createdAt: now, updatedAt: now);

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
      final act1 = savedAct(
          id: 1,
          memId: 1,
          start: now,
          startIsAllDay: false,
          end: now.add(const Duration(hours: 1)),
          endIsAllDay: false,
          createdAt: now,
          updatedAt: now);
      final act2 = savedAct(
          id: 2,
          memId: 1,
          start: now.add(const Duration(hours: 2)),
          startIsAllDay: false,
          end: now.add(const Duration(hours: 3)),
          endIsAllDay: false,
          createdAt: now,
          updatedAt: now);

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

    test('triggers async fetch when isUpdating is false', () {
      runZonedGuarded(() {
        final container = ProviderContainer(
          overrides: [
            actEntitiesProvider.overrideWith(() => _FakeActEntities()),
          ],
        );
        addTearDown(container.dispose);

        container.read(isUpdating(1).notifier).updatedBy(false);

        final list = container.read(actListProvider(1));

        expect(list, isA<List<SavedActEntityV1>>());
      }, (error, stack) {
        // ActsClient().fetch() が呼ばれるため、エラーが発生する可能性がある
      });
    });

    test('fetches byPage when currentPage is not 1', () {
      runZonedGuarded(() {
        final container = ProviderContainer(
          overrides: [
            actEntitiesProvider.overrideWith(() => _FakeActEntities()),
          ],
        );
        addTearDown(container.dispose);

        container.read(isUpdating(1).notifier).updatedBy(false);
        container.read(currentPage(1).notifier).updatedBy(2);
        container.read(maxPage(1).notifier).updatedBy(2);

        final list = container.read(actListProvider(1));

        expect(list, isA<List<SavedActEntityV1>>());
      }, (error, stack) {
        // ActsClient().fetch() が呼ばれるため、エラーが発生する可能性がある
      });
    });
  });

  group('ActCountsByMemIdByDate', () {
    test(
      'load stores window acts and an older latest act, and counts each window',
      () async {
        final db = await _openMemoryDatabase();
        final container = ProviderContainer(
          overrides: [
            preferenceProvider(startOfDayKey)
                .overrideWith(() => _FakePreference()),
          ],
        );
        addTearDown(container.dispose);

        // この時刻の論理日。startOfDay は 0:00 なので、日窓は当日、週窓は 11/3 0:00 から 11/10 0:00 の手前
        final now = DateTime(2026, 11, 9, 10);
        final createdAt = DateTime(2026, 6, 1);
        // 回。日窓にも週窓にも 2 件ある。1 件だと mem あたり 1 で止まる数え方と区別できない
        const actsInsideWindow = 2;

        Future<int> insertMem(String name) async =>
            (await db.into(db.mems).insertReturning(
                      MemsCompanion.insert(name: name, createdAt: createdAt),
                    ))
                .id;

        Future<int> insertAct({
          required int memId,
          required DateTime start,
          String actKind = 'finished',
        }) =>
            db.into(db.acts).insert(
                  ActsCompanion.insert(
                    memId: memId,
                    createdAt: createdAt,
                    start: Value(start),
                    end: Value(start.add(const Duration(hours: 1))),
                    actKind: Value(actKind),
                  ),
                );

        final oldMemId = await insertMem('old');
        final dailyMemId = await insertMem('daily');
        final weeklyMemId = await insertMem('weekly');

        // 日窓の外。この mem ではこれが最新
        final oldLatestId = await insertAct(
          memId: oldMemId,
          start: DateTime(2026, 10, 1, 12),
        );
        final todayEarlyId = await insertAct(
          memId: dailyMemId,
          start: DateTime(2026, 11, 9, 8),
        );
        final todayLateId = await insertAct(
          memId: dailyMemId,
          start: DateTime(2026, 11, 9, 9),
        );
        // 日窓の中だが skip。件数には入らない。最新なので act の状態には残る
        final skippedTodayId = await insertAct(
          memId: dailyMemId,
          start: DateTime(2026, 11, 9, 11),
          actKind: 'skipped',
        );
        // 日窓の外で、最新でもない
        final yesterdayId = await insertAct(
          memId: dailyMemId,
          start: DateTime(2026, 11, 8, 12),
        );
        // 週窓の中で、今日より前
        final weekInsidePastId = await insertAct(
          memId: weeklyMemId,
          start: DateTime(2026, 11, 4, 15),
        );
        final weekLatestStart = DateTime(2026, 11, 8, 12);
        final weekLatestId = await insertAct(
          memId: weeklyMemId,
          start: weekLatestStart,
        );
        // 週窓の開始より前。最新でもない
        final weekOutsideId = await insertAct(
          memId: weeklyMemId,
          start: DateTime(2026, 11, 1, 12),
        );

        Target countTarget(int memId, Period period) => Target(
              memId: memId,
              targetType: TargetType.equalTo,
              targetUnit: TargetUnit.count,
              value: actsInsideWindow,
              period: period,
            );

        container.read(memEntitiesProvider.notifier).upsert([
          savedMem(
            id: oldMemId,
            name: 'old',
            createdAt: createdAt,
            updatedAt: createdAt,
            target: countTarget(oldMemId, Period.aDay),
          ),
          savedMem(
            id: dailyMemId,
            name: 'daily',
            createdAt: createdAt,
            updatedAt: createdAt,
            target: countTarget(dailyMemId, Period.aDay),
          ),
          savedMem(
            id: weeklyMemId,
            name: 'weekly',
            createdAt: createdAt,
            updatedAt: createdAt,
            latestAct: Act.by(
              weeklyMemId,
              startWhen: DateAndTime.from(
                weekLatestStart,
                timeOfDay: weekLatestStart,
              ),
              endWhen: DateAndTime.from(
                weekLatestStart.add(const Duration(hours: 1)),
                timeOfDay: weekLatestStart.add(const Duration(hours: 1)),
              ),
            ),
            target: countTarget(weeklyMemId, Period.aWeek),
          ),
        ]);

        final counts = await container
            .read(actCountsByMemIdByDateProvider(now).notifier)
            .load();

        expect(
          container.read(actEntitiesProvider).map((act) => act.id).toSet(),
          {
            oldLatestId,
            todayEarlyId,
            todayLateId,
            skippedTodayId,
            weekInsidePastId,
            weekLatestId,
          },
        );
        expect(counts, {
          oldMemId: 0,
          dailyMemId: actsInsideWindow,
          weeklyMemId: actsInsideWindow,
        });

        // act を upsert し直すと build が同じ窓で数え直す
        container
            .read(actEntitiesProvider.notifier)
            .upsert(container.read(actEntitiesProvider));
        expect(
          container.read(actCountsByMemIdByDateProvider(now)),
          {
            oldMemId: 0,
            dailyMemId: actsInsideWindow,
            weeklyMemId: actsInsideWindow,
          },
        );
        expect(
          container.read(actEntitiesProvider).map((act) => act.id),
          isNot(contains(yesterdayId)),
        );
        expect(
          container.read(actEntitiesProvider).map((act) => act.id),
          isNot(contains(weekOutsideId)),
        );
      },
    );
  });
}
