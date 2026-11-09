import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act, Target;
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/today_act_count.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  group('TodayActCount', () {
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
      String? actKind,
    }) async {
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: start,
              start: Value(start),
              end: Value(start.add(const Duration(minutes: 1))),
              actKind: Value(actKind),
            ),
          );
    }

    Target dailyCount({int value = 4}) => Target(
          memId: 0,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: value,
          period: Period.aDay,
        );

    test('counts non-skipped starts on the logical day of that mem', () async {
      final memId = await insertMem();
      final otherMemId = await insertMem();
      const startOfDay = TimeOfDay(hour: 5, minute: 0);
      final now = DateTime(2026, 11, 9, 10);
      await insertAct(memId: memId, start: DateTime(2026, 11, 9, 4));
      await insertAct(
        memId: memId,
        start: DateTime(2026, 11, 9, 6),
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: DateTime(2026, 11, 9, 7),
        actKind: 'skipped',
      );
      await insertAct(memId: memId, start: DateTime(2026, 11, 10, 4));
      await insertAct(memId: memId, start: DateTime(2026, 11, 10, 5));
      await insertAct(memId: otherMemId, start: DateTime(2026, 11, 9, 6));

      final count = await TodayActCount.of(
        target: dailyCount(),
        memId: memId,
        startOfDay: startOfDay,
        now: now,
      );

      expect(count?.value, 2);
    });

    test('is null when the mem is not a daily count of two or more', () async {
      final memId = await insertMem();
      await insertAct(memId: memId, start: DateTime(2026, 11, 9, 12));

      final count = await TodayActCount.of(
        target: dailyCount(value: 1),
        memId: memId,
        startOfDay: const TimeOfDay(hour: 0, minute: 0),
        now: DateTime(2026, 11, 9, 15),
      );

      expect(count, isNull);
    });
  });
}
