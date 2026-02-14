import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/entity.dart';

mixin DatabaseTupleEntityV1<PRIMARY_KEY, T> on EntityV1<T> {
  late PRIMARY_KEY id;
  late DateTime createdAt;
  late DateTime? updatedAt;
  late DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  void withMap(Map<String, Object?> map) {
    id = map[defPkId.name] as PRIMARY_KEY;
    final rawCreatedAt = map[defColCreatedAt.name];
    if (rawCreatedAt is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else {
      createdAt = map[defColCreatedAt.name] as DateTime;
    }
    final rawUpdatedAt = map[defColUpdatedAt.name];
    if (rawUpdatedAt is int) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt);
    } else {
      updatedAt = map[defColUpdatedAt.name] as DateTime?;
    }
    final rawArchivedAt = map[defColArchivedAt.name];
    if (rawArchivedAt is int) {
      archivedAt = DateTime.fromMillisecondsSinceEpoch(rawArchivedAt);
    } else {
      archivedAt = map[defColArchivedAt.name] as DateTime?;
    }
  }

  @override
  Map<String, Object?> get toMap => super.toMap
    ..addAll({
      defPkId.name: id,
      defColCreatedAt.name: createdAt,
      defColUpdatedAt.name: updatedAt,
      defColArchivedAt.name: archivedAt,
    });
}

final Map<Type, TableDefinition> entityTableRelations = {
  MemEntityV1: defTableMems,
  MemItemEntity: defTableMemItems,
  MemNotificationEntityV1: defTableMemNotifications,
  TargetEntity: defTableTargets,
  MemRelationEntity: defTableMemRelations,
};
