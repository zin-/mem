import 'package:drift/drift.dart' show Migrator, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem;
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/singleton.dart';

class _TestMemRepo extends DatabaseTupleRepository<Mem, int, MemEntity> {
  _TestMemRepo() : super(databaseDefinition, defTableMems);
}

void main() {
  group('wasteV2 child cascade', () {
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

    test('deletes child rows before parent mem', () async {
      final now = DateTime.now();
      final m1 = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm1', createdAt: now),
          );
      final m2 = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm2', createdAt: now),
          );

      await db.into(db.memItems).insert(
            MemItemsCompanion.insert(
              memId: m1.id,
              type: 'memo',
              value: 'a',
              createdAt: now,
            ),
          );
      await db.into(db.acts).insert(
            ActsCompanion.insert(createdAt: now, memId: m1.id),
          );
      await db.into(db.memRepeatedNotifications).insert(
            MemRepeatedNotificationsCompanion.insert(
              createdAt: now,
              timeOfDaySeconds: 0,
              type: MemNotificationType.repeat.name,
              message: 'm',
              memId: m1.id,
            ),
          );
      await db.into(db.targets).insert(
            TargetsCompanion.insert(
              createdAt: now,
              type: TargetType.equalTo.name,
              unit: TargetUnit.count.name,
              value: 1,
              period: Period.aDay.name,
              memId: m1.id,
            ),
          );
      await db.into(db.memRelations).insert(
            MemRelationsCompanion.insert(
              createdAt: now,
              sourceMemId: m1.id,
              targetMemId: m2.id,
              type: MemRelationType.prePost.name,
              value: const Value(0),
            ),
          );

      await _TestMemRepo().wasteV2(condition: Equals(defPkId, m1.id));

      expect(await db.select(db.mems).get(), hasLength(1));
      expect((await db.select(db.mems).get()).single.id, m2.id);

      expect(await db.select(db.memItems).get(), isEmpty);
      expect(await db.select(db.acts).get(), isEmpty);
      expect(await db.select(db.memRepeatedNotifications).get(), isEmpty);
      expect(await db.select(db.targets).get(), isEmpty);
      expect(await db.select(db.memRelations).get(), isEmpty);
    });
  });
}
