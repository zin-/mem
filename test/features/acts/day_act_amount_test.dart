import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/singleton.dart';

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference(this.startOfDay);

  final TimeOfDay startOfDay;

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) => startOfDay;
}

void main() {
  group('viewedDayActAmount', () {
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
      DateTime? end,
      String? actKind,
    }) async {
      final now = DateTime.now();
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: now,
              start: Value(start),
              end: Value(end),
              actKind: Value(actKind),
            ),
          );
    }

    ProviderContainer container(TimeOfDay startOfDay) {
      final result = ProviderContainer(
        overrides: [
          preferenceProvider(startOfDayKey)
              .overrideWith(() => _FakePreference(startOfDay)),
        ],
      );
      addTearDown(result.dispose);
      return result;
    }

    test('uses the viewed day and not another day', () async {
      final memId = await insertMem();
      final otherMemId = await insertMem();
      final oct30 = DateTime(2026, 10, 30, 10);
      final oct31 = DateTime(2026, 10, 31, 10);
      await insertAct(
        memId: memId,
        start: oct30,
        end: oct30.add(const Duration(hours: 1)),
      );
      await insertAct(
        memId: memId,
        start: oct30.add(const Duration(hours: 2)),
        end: oct30.add(const Duration(hours: 2)),
        actKind: 'skipped',
      );
      await insertAct(
        memId: memId,
        start: oct30.add(const Duration(hours: 5)),
      );
      await insertAct(
        memId: memId,
        start: oct31,
        end: oct31.add(const Duration(hours: 2)),
      );
      await insertAct(
        memId: otherMemId,
        start: oct30,
        end: oct30.add(const Duration(hours: 3)),
      );

      final scope = container(const TimeOfDay(hour: 0, minute: 0));
      final on30 = await scope.read(
        viewedDayActAmountProvider(memId, DateTime(2026, 10, 30)).future,
      );
      final on31 = await scope.read(
        viewedDayActAmountProvider(memId, DateTime(2026, 10, 31)).future,
      );

      expect(on30.count, 2);
      expect(on30.recorded, const Duration(hours: 1));
      expect(on31.count, 1);
      expect(on31.recorded, const Duration(hours: 2));
    });

    test('startOfDay keeps the next morning on the viewed day', () async {
      final memId = await insertMem();
      final early = DateTime(2026, 10, 31, 3);
      final later = DateTime(2026, 10, 31, 6);
      await insertAct(
        memId: memId,
        start: early,
        end: early.add(const Duration(hours: 1)),
      );
      await insertAct(
        memId: memId,
        start: later,
        end: later.add(const Duration(hours: 1)),
      );

      final scope = container(const TimeOfDay(hour: 5, minute: 0));
      final on30 = await scope.read(
        viewedDayActAmountProvider(memId, DateTime(2026, 10, 30)).future,
      );
      final on31 = await scope.read(
        viewedDayActAmountProvider(memId, DateTime(2026, 10, 31)).future,
      );

      expect(on30.count, 1);
      expect(on30.recorded, const Duration(hours: 1));
      expect(on31.count, 1);
      expect(on31.recorded, const Duration(hours: 1));
    });
  });
}
