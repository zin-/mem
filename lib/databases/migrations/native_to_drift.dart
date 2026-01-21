import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/framework/database/factory.dart';

Future migrateNativeToDrift(AppDatabase database) async {
  final dbAccessor = await DatabaseFactory.open(databaseDefinition);

  final allMemsRaw = await dbAccessor.select(defTableMems);
  final allMems = allMemsRaw.map((e) => SavedMemEntity(e)).toList();

  final allMemItemsRaw = await dbAccessor.select(defTableMemItems);
  final allMemItems = allMemItemsRaw.map((e) => SavedMemItemEntity(e)).toList();

  final allActsRaw = await dbAccessor.select(defTableActs);
  final allActs = allActsRaw.map((e) => SavedActEntity(e)).toList();

  final allMemNotificationsRaw =
      await dbAccessor.select(defTableMemNotifications);
  final allMemNotifications =
      allMemNotificationsRaw.map((e) => SavedMemNotificationEntity(e)).toList();

  final allTargetsRaw = await dbAccessor.select(defTableTargets);
  final allTargets = allTargetsRaw.map((e) => SavedTargetEntity(e)).toList();

  final allMemRelationsRaw = await dbAccessor.select(defTableMemRelations);
  final allMemRelations =
      allMemRelationsRaw.map((e) => SavedMemRelationEntity(e)).toList();

  try {
    await database.batch((batch) {
      for (final e in allMems) {
        batch.insert(
          database.mems,
          MemsCompanion.insert(
            name: e.value.name,
            doneAt: Value(e.value.doneAt),
            notifyOn: Value(e.value.period?.start),
            notifyAt: Value(e.value.period?.start?.isAllDay == true
                ? null
                : e.value.period?.start),
            endOn: Value(e.value.period?.end),
            endAt: Value(e.value.period?.end?.isAllDay == true
                ? null
                : e.value.period?.end),
            id: Value(e.id),
            createdAt: e.createdAt,
            updatedAt: Value(e.updatedAt),
            archivedAt: Value(e.archivedAt),
          ),
          mode: InsertMode.replace,
        );
      }

      for (final e in allMemItems) {
        batch.insert(
          database.memItems,
          MemItemsCompanion.insert(
            type: e.value.type.name,
            value: e.value.value,
            memId: e.value.memId!,
            id: Value(e.id),
            createdAt: e.createdAt,
            updatedAt: Value(e.updatedAt),
            archivedAt: Value(e.archivedAt),
          ),
          mode: InsertMode.replace,
        );
      }

      for (final e in allActs) {
        batch.insert(
          database.acts,
          ActsCompanion.insert(
            start: Value(e.value.period?.start),
            startIsAllDay: Value(e.value.period?.start?.isAllDay),
            end: Value(e.value.period?.end),
            endIsAllDay: Value(e.value.period?.end?.isAllDay),
            pausedAt: Value(e.value.pausedAt),
            memId: e.value.memId,
            id: Value(e.id),
            createdAt: e.createdAt,
            updatedAt: Value(e.updatedAt),
            archivedAt: Value(e.archivedAt),
          ),
          mode: InsertMode.replace,
        );
      }

      for (final e in allMemNotifications) {
        batch.insert(
          database.memRepeatedNotifications,
          MemRepeatedNotificationsCompanion.insert(
            timeOfDaySeconds: e.value.time ?? 0,
            type: e.value.type.name,
            message: e.value.message,
            memId: e.value.memId ?? 0,
            id: Value(e.id),
            createdAt: e.createdAt,
            updatedAt: Value(e.updatedAt),
            archivedAt: Value(e.archivedAt),
          ),
          mode: InsertMode.replace,
        );
      }

      for (final e in allTargets) {
        batch.insert(
          database.targets,
          TargetsCompanion.insert(
            type: e.value.targetType.name,
            unit: e.value.targetUnit.name,
            value: e.value.value,
            period: e.value.period.name,
            memId: e.value.memId ?? 0,
            id: Value(e.id),
            createdAt: e.createdAt,
            updatedAt: Value(e.updatedAt),
            archivedAt: Value(e.archivedAt),
          ),
          mode: InsertMode.replace,
        );
      }

      for (final e in allMemRelations) {
        batch.insert(
          database.memRelations,
          MemRelationsCompanion.insert(
            sourceMemId: e.value.sourceMemId,
            targetMemId: e.value.targetMemId,
            type: e.value.type.name,
            value: Value(e.value.value),
            id: Value(e.id),
            createdAt: e.createdAt,
            updatedAt: Value(e.updatedAt),
            archivedAt: Value(e.archivedAt),
          ),
          mode: InsertMode.replace,
        );
      }
    });
  } catch (e, stackTrace) {
    throw Exception(
      'Migration failed: $e\n'
      'Stack trace: $stackTrace\n'
      'Mems count: ${allMems.length}\n'
      'MemItems count: ${allMemItems.length}\n'
      'Acts count: ${allActs.length}\n'
      'MemNotifications count: ${allMemNotifications.length}\n'
      'Targets count: ${allTargets.length}\n'
      'MemRelations count: ${allMemRelations.length}',
    );
  }
}
