import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/acts/act.dart';

void main() {
  group('act_kind migration', () {
    test('backfillFinishedActKind sets finished on completed rows only', () async {
      final db = AppDatabase.memory();
      await Migrator(db).createAll();
      final now = DateTime(2024, 6, 1, 12);
      final mem = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );

      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: mem.id,
              createdAt: now,
              start: Value(now),
              end: Value(now.add(const Duration(hours: 1))),
            ),
          );
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: mem.id,
              createdAt: now,
              pausedAt: Value(now),
            ),
          );

      await backfillFinishedActKind(db);

      final rows = await db.select(db.acts).get();
      final finishedRow =
          rows.singleWhere((row) => row.start != null && row.end != null);
      final pausedRow = rows.singleWhere((row) => row.pausedAt != null);

      expect(finishedRow.actKind, ActKind.finished.name);
      expect(pausedRow.actKind, isNull);
      await db.close();
    });

    test('onUpgrade from 1 to 2 adds act_kind and backfills', () async {
      final db = AppDatabase.memory();
      await Migrator(db).createAll();
      final now = DateTime(2024, 6, 2, 12);
      final mem = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: mem.id,
              createdAt: now,
              start: Value(now),
              end: Value(now.add(const Duration(hours: 1))),
              actKind: const Value(null),
            ),
          );

      await db.customStatement('ALTER TABLE acts DROP COLUMN act_kind');
      await db.migration.onUpgrade(Migrator(db), 1, 2);

      final row = await db.select(db.acts).getSingle();
      expect(row.actKind, ActKind.finished.name);
      await db.close();
    });
  });
}
