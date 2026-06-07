import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  group('MemRepository loadLatestAct', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Migrator(db).createAll();
      DriftDatabaseAccessor.reset();
      Singleton.override<DriftDatabaseAccessor>(
        DriftDatabaseAccessor.withDatabase(db),
      );
      Singleton.reset<MemRepository>();
    });

    tearDown(() async {
      await db.close();
      DriftDatabaseAccessor.reset();
      Singleton.reset<MemRepository>();
    });

    test('attaches latest act per mem by start then id', () async {
      final now = DateTime.now();
      final m1 = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'a', createdAt: now),
          );
      final m2 = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'b', createdAt: now),
          );
      final actOlder = await db.into(db.acts).insertReturning(
            ActsCompanion.insert(
              memId: m1.id,
              createdAt: now.subtract(const Duration(hours: 2)),
              start: Value(now.subtract(const Duration(days: 1))),
            ),
          );
      final actNewer = await db.into(db.acts).insertReturning(
            ActsCompanion.insert(
              memId: m1.id,
              createdAt: now,
              start: Value(now),
            ),
          );

      final rows = await MemRepository().ship(loadLatestAct: true);

      expect(rows, hasLength(2));
      final mem1 = rows.cast<MemEntity>().singleWhere((e) => e.id == m1.id);
      final mem2 = rows.cast<MemEntity>().singleWhere((e) => e.id == m2.id);
      expect(mem1.latestAct?.memId, m1.id);
      expect(mem1.latestAct?.period?.start?.day, now.day);
      expect(mem2.latestAct, isNull);
      expect(actOlder.id, lessThan(actNewer.id));
    });

    test('latest_act includes skipped row when it is the newest', () async {
      final now = DateTime.now();
      final mem = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: mem.id,
              createdAt: now.subtract(const Duration(days: 2)),
              start: Value(now.subtract(const Duration(days: 2))),
              end: Value(now.subtract(const Duration(days: 2))),
              actKind: const Value('finished'),
            ),
          );
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: mem.id,
              createdAt: now,
              start: Value(now.subtract(const Duration(days: 1))),
              end: Value(now.subtract(const Duration(days: 1))),
              actKind: const Value('skipped'),
            ),
          );

      final rows = await MemRepository().ship(
        id: mem.id,
        loadLatestAct: true,
      );

      final loaded = rows.single;
      expect(loaded.latestAct?.actKind, ActKind.skipped);
    });

    test('attaches scheduleAnchorAct when latest act is skipped', () async {
      final now = DateTime.now();
      final mem = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );
      final finishStart = now.subtract(const Duration(days: 2));
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: mem.id,
              createdAt: finishStart,
              start: Value(finishStart),
              end: Value(finishStart),
              actKind: const Value('finished'),
            ),
          );
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: mem.id,
              createdAt: now,
              start: Value(now.subtract(const Duration(days: 1))),
              end: Value(now.subtract(const Duration(days: 1))),
              actKind: const Value('skipped'),
            ),
          );

      final rows = await MemRepository().ship(
        id: mem.id,
        loadLatestAct: true,
      );

      final loaded = rows.single;
      expect(loaded.latestAct?.actKind, ActKind.skipped);
      expect(loaded.scheduleAnchorAct?.actKind, ActKind.finished);
      expect(
        loaded.scheduleAnchorAct?.period?.start?.day,
        finishStart.day,
      );
    });
  });
}
