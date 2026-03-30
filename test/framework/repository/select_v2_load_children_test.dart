import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/load_child_spec.dart';
import 'package:mem/framework/repository/order_by.dart';

void main() {
  group('selectV2 loadChildren', () {
    late AppDatabase db;
    late DriftDatabaseAccessor accessor;

    setUp(() async {
      db = AppDatabase.memory();
      accessor = DriftDatabaseAccessor.withDatabase(db);
      await Migrator(db).createAll();
    });

    tearDown(() async {
      await db.close();
    });

    test('child condition filters rows', () async {
      final now = DateTime.now();
      final m = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );
      await db.into(db.memItems).insert(
            MemItemsCompanion.insert(
              memId: m.id,
              type: 'memo',
              value: 'a',
              createdAt: now,
            ),
          );
      await db.into(db.memItems).insert(
            MemItemsCompanion.insert(
              memId: m.id,
              type: 'memo',
              value: 'b',
              createdAt: now,
            ),
          );

      final rows = await accessor.selectV2(
        defTableMems,
        loadChildren: [
          LoadChildSpec(
            table: defTableMemItems,
            condition: Equals(defColMemItemsValue, 'a'),
          ),
        ],
      );

      final entity = rows.single as MemEntity;
      expect(entity.items, hasLength(1));
      expect(entity.items!.single.value, 'a');
    });

    test('multiple child tables', () async {
      final now = DateTime.now();
      final m = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );
      await db.into(db.memItems).insert(
            MemItemsCompanion.insert(
              memId: m.id,
              type: 'memo',
              value: 'v',
              createdAt: now,
            ),
          );
      await db.into(db.memRepeatedNotifications).insert(
            MemRepeatedNotificationsCompanion.insert(
              createdAt: now,
              timeOfDaySeconds: 3600,
              type: 'repeat',
              message: 'msg',
              memId: m.id,
            ),
          );

      final rows = await accessor.selectV2(
        defTableMems,
        loadChildren: [
          LoadChildSpec(table: defTableMemItems),
          LoadChildSpec(table: defTableMemNotifications),
        ],
      );

      final entity = rows.single as MemEntity;
      expect(entity.items, hasLength(1));
      expect(entity.repeatedNotifications, hasLength(1));
      expect(entity.repeatedNotifications!.single.message, 'msg');
    });

    test('mem_relations by sourceMemId', () async {
      final now = DateTime.now();
      final a = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'a', createdAt: now),
          );
      final b = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'b', createdAt: now),
          );
      await db.into(db.memRelations).insert(
            MemRelationsCompanion.insert(
              createdAt: now,
              sourceMemId: a.id,
              targetMemId: b.id,
              type: 'prePost',
              value: const Value(5),
            ),
          );

      final rows = await accessor.selectV2(
        defTableMems,
        condition: Equals(defPkId, a.id),
        loadChildren: [
          LoadChildSpec(
            table: defTableMemRelations,
            fkToParent: defFkMemRelationsSourceMemId,
          ),
        ],
      );

      final memA = rows.single as MemEntity;
      expect(memA.memRelations, hasLength(1));
      expect(memA.memRelations!.single.targetMemId, b.id);
    });

    test('mem_relations by targetMemId', () async {
      final now = DateTime.now();
      final a = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'a', createdAt: now),
          );
      final b = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'b', createdAt: now),
          );
      await db.into(db.memRelations).insert(
            MemRelationsCompanion.insert(
              createdAt: now,
              sourceMemId: a.id,
              targetMemId: b.id,
              type: 'prePost',
              value: const Value(5),
            ),
          );

      final rows = await accessor.selectV2(
        defTableMems,
        condition: Equals(defPkId, b.id),
        loadChildren: [
          LoadChildSpec(
            table: defTableMemRelations,
            fkToParent: defFkMemRelationsTargetMemId,
          ),
        ],
      );

      final memB = rows.single as MemEntity;
      expect(memB.memRelations, hasLength(1));
      expect(memB.memRelations!.single.sourceMemId, a.id);
    });

    test('acts latest_act per mem via orderBy and limit', () async {
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

      final rows = await accessor.selectV2(
        defTableMems,
        loadChildren: [
          LoadChildSpec(
            table: defTableActs,
            resultKey: 'latest_act',
            orderBy: [
              DescendingCoalesce(defColActsStart, defColCreatedAt),
              Descending(defPkId),
            ],
            limit: 1,
          ),
        ],
      );

      expect(rows, hasLength(2));
      final mem1 = rows.cast<MemEntity>().singleWhere((e) => e.id == m1.id);
      final mem2 = rows.cast<MemEntity>().singleWhere((e) => e.id == m2.id);
      expect(mem1.latestAct?.memId, m1.id);
      expect(mem1.latestAct?.period?.start?.day, now.day);
      expect(mem2.latestAct, isNull);
      expect(actOlder.id, lessThan(actNewer.id));
    });

    test('duplicate resultKey throws', () async {
      final now = DateTime.now();
      await db.into(db.mems).insert(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );

      await expectLater(
        accessor.selectV2(
          defTableMems,
          loadChildren: [
            LoadChildSpec(table: defTableMemItems),
            LoadChildSpec(
              table: defTableMemItems,
              resultKey: defTableMemItems.name,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
