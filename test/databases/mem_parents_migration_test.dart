import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem, MemParent;

void main() {
  test('onUpgrade from 3 to 4 creates mem_parents', () async {
    final db = AppDatabase.memory();
    await Migrator(db).createAll();
    await db.customStatement('DROP TABLE mem_parents');

    await db.migration.onUpgrade(Migrator(db), 3, 4);

    final now = DateTime(2024, 6, 3, 12);
    final child = await db.into(db.mems).insertReturning(
          MemsCompanion.insert(name: 'child', createdAt: now),
        );
    final parent = await db.into(db.mems).insertReturning(
          MemsCompanion.insert(name: 'parent', createdAt: now),
        );
    await db.into(db.memParents).insert(
          MemParentsCompanion.insert(
            memId: child.id,
            parentMemId: parent.id,
            createdAt: now,
          ),
        );

    final row = await db.select(db.memParents).getSingle();
    expect(row.memId, child.id);
    expect(row.parentMemId, parent.id);
    await db.close();
  });
}
