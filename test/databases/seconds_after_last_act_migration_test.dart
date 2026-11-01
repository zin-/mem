import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Target;
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/targets/target.dart';

void main() {
  test('onUpgrade from 2 to 3 adds seconds_after_last_act as null', () async {
    final db = AppDatabase.memory();
    await Migrator(db).createAll();
    final now = DateTime(2024, 6, 3, 12);
    final mem = await db.into(db.mems).insertReturning(
          MemsCompanion.insert(name: 'm', createdAt: now),
        );
    await db.into(db.targets).insert(
          TargetsCompanion.insert(
            type: TargetType.equalTo.name,
            unit: TargetUnit.count.name,
            value: 2,
            period: Period.aDay.name,
            memId: mem.id,
            createdAt: now,
          ),
        );

    await db.customStatement(
      'ALTER TABLE targets DROP COLUMN seconds_after_last_act',
    );
    await db.migration.onUpgrade(Migrator(db), 2, 3);

    final row = await db.select(db.targets).getSingle();
    expect(row.secondsAfterLastAct, isNull);
    await db.close();
  });
}
