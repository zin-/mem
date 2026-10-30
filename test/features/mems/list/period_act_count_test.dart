import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/list/period_act_count.dart';
import 'package:mem/features/mems/mem_store.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/singleton.dart';

class _FakePreference extends Preference<TimeOfDay> {
  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 0, minute: 0);
}

void main() {
  group('periodActCount', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Migrator(db).createAll();
      DriftDatabaseAccessor.reset();
      Singleton.override<DriftDatabaseAccessor>(
        DriftDatabaseAccessor.withDatabase(db),
      );
    });

    tearDown(() async {
      MemStore.resetSingleton();
      await db.close();
      DriftDatabaseAccessor.reset();
    });

    Future<int> insertMem() async {
      final now = DateTime.now();
      return (await db.into(db.mems).insertReturning(
                MemsCompanion.insert(name: 'm', createdAt: now),
              ))
          .id;
    }

    Future<void> insertAct({
      required int memId,
      required DateTime start,
      String? actKind,
    }) async {
      final now = DateTime.now();
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: now,
              start: Value(start),
              end: Value(start.add(const Duration(minutes: 1))),
              actKind: Value(actKind),
            ),
          );
    }

    Future<void> insertTarget({
      required int memId,
      required TargetUnit unit,
      required int value,
    }) async {
      await db.into(db.targets).insert(
            TargetsCompanion.insert(
              type: TargetType.equalTo.name,
              unit: unit.name,
              value: value,
              period: Period.aDay.name,
              memId: memId,
              createdAt: DateTime.now(),
            ),
          );
    }

    ProviderContainer container() {
      final result = ProviderContainer(
        overrides: [
          preferenceProvider(startOfDayKey)
              .overrideWith(() => _FakePreference()),
        ],
      );
      addTearDown(result.dispose);
      return result;
    }

    test('counts non-skipped acts in the target period', () async {
      final memId = await insertMem();
      final otherMemId = await insertMem();
      await insertTarget(memId: memId, unit: TargetUnit.count, value: 3);
      final now = DateTime.now();
      final noon = DateTime(now.year, now.month, now.day, 12);
      final yesterdayNoon = noon.subtract(const Duration(days: 1));
      await insertAct(memId: memId, start: noon);
      await insertAct(
        memId: memId,
        start: noon.add(const Duration(hours: 1)),
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: noon.add(const Duration(hours: 2)),
        actKind: 'skipped',
      );
      await insertAct(memId: memId, start: yesterdayNoon);
      await insertAct(memId: otherMemId, start: noon);

      final scope = container();
      await scope.read(memEntitiesProvider.notifier).loadMemList();
      final progress = await scope.read(periodActCountProvider(memId).future);

      expect(
        scope
            .read(memEntitiesProvider)
            .singleWhere((e) => e.id == memId)
            .target
            ?.value,
        3,
      );
      expect(progress?.count, 2);
      expect(progress?.targetValue, 3);
    });

    test('is null when the target unit is time', () async {
      final memId = await insertMem();
      await insertTarget(memId: memId, unit: TargetUnit.time, value: 60);
      final now = DateTime.now();
      await insertAct(
        memId: memId,
        start: DateTime(now.year, now.month, now.day, 12),
      );

      final scope = container();
      await scope.read(memEntitiesProvider.notifier).loadMemList();
      final progress = await scope.read(periodActCountProvider(memId).future);

      expect(progress, isNull);
    });
  });
}
