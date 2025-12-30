import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/targets/target_repository.dart';

Future migrateNativeToDrift(AppDatabase database) async {
  final allMems = await MemRepository().ship();
  final allMemItems = await MemItemRepository().ship();
  final allActs = await ActRepository().ship();
  final allMemNotifications = await MemNotificationRepository().ship();
  final allTargets = await TargetRepository().ship();
  final allMemRelations = await MemRelationRepository().ship();

  await database.batch((batch) async {
    batch.insertAll(
        database.mems,
        allMems.map(
          (e) => MemsCompanion.insert(
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
        ));

    batch.insertAll(
        database.memItems,
        allMemItems.map(
          (e) => MemItemsCompanion.insert(
            type: e.value.type.name,
            value: e.value.value,
            memId: e.value.memId!,
            id: Value(e.id),
            createdAt: e.createdAt,
            updatedAt: Value(e.updatedAt),
            archivedAt: Value(e.archivedAt),
          ),
        ));

    batch.insertAll(
        database.acts,
        allActs.map(
          (e) => ActsCompanion.insert(
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
        ));

    batch.insertAll(
        database.memRepeatedNotifications,
        allMemNotifications.map(
          (e) => MemRepeatedNotificationsCompanion.insert(
            timeOfDaySeconds: e.value.time ?? 0,
            type: e.value.type.name,
            message: e.value.message,
            memId: e.value.memId ?? 0,
            id: Value(e.id),
            createdAt: e.createdAt,
            updatedAt: Value(e.updatedAt),
            archivedAt: Value(e.archivedAt),
          ),
        ));

    batch.insertAll(
        database.targets,
        allTargets.map(
          (e) => TargetsCompanion.insert(
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
        ));

    batch.insertAll(
        database.memRelations,
        allMemRelations.map(
          (e) => MemRelationsCompanion.insert(
            sourceMemId: e.value.sourceMemId,
            targetMemId: e.value.targetMemId,
            type: e.value.type.name,
            value: Value(e.value.value),
            id: Value(e.id),
            createdAt: e.createdAt,
            updatedAt: Value(e.updatedAt),
            archivedAt: Value(e.archivedAt),
          ),
        ));
  });
}
