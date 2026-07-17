import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_period_db.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/view/identifiable.dart';

class MemEntity implements Entity<int>, Identifiable<int> {
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;
  final List<MemItemEntity>? items;
  final List<MemNotificationEntity>? repeatedNotifications;
  final List<MemRelationEntity>? memRelations;
  final Act? latestAct;
  final Act? scheduleAnchorAct;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  MemEntity(
    this.id,
    this.name,
    this.doneAt,
    this.period,
    this.items,
    this.createdAt,
    this.updatedAt,
    this.archivedAt, {
    this.repeatedNotifications,
    this.memRelations,
    this.latestAct,
    this.scheduleAnchorAct,
  });

  Mem toDomain() => Mem(
        id,
        name,
        doneAt,
        period,
        latestAct: latestAct,
        scheduleAnchorAct: scheduleAnchorAct,
      );

  Act? get resolvedScheduleAnchor => scheduleAnchorForNotifications(
        latestAct: latestAct,
        scheduleAnchorAct: scheduleAnchorAct,
      );

  MemEntity updatedWith({
    Mem Function(Mem mem)? update,
    List<MemItemEntity>? Function()? items,
    List<MemNotificationEntity>? Function()? repeatedNotifications,
    List<MemRelationEntity>? Function()? memRelations,
    Act? Function()? latestAct,
    Act? Function()? scheduleAnchorAct,
    DateTime? Function()? updatedAt,
    DateTime? Function()? archivedAt,
  }) {
    final updated = update == null ? toDomain() : update(toDomain());
    return MemEntity(
      id,
      updated.name,
      updated.doneAt,
      updated.period,
      items == null ? this.items : items(),
      createdAt,
      updatedAt == null ? this.updatedAt : updatedAt(),
      archivedAt == null ? this.archivedAt : archivedAt(),
      repeatedNotifications: repeatedNotifications == null
          ? this.repeatedNotifications
          : repeatedNotifications(),
      memRelations: memRelations == null ? this.memRelations : memRelations(),
      latestAct: latestAct == null ? this.latestAct : latestAct(),
      scheduleAnchorAct:
          scheduleAnchorAct == null ? this.scheduleAnchorAct : scheduleAnchorAct(),
    );
  }

  factory MemEntity.fromTuple(
    dynamic row, {
    Map<String, dynamic> children = const {},
  }) {
    final memItemsRaw = children['mem_items'];
    final memItems = memItemsRaw == null
        ? null
        : List<MemItemEntity>.from(memItemsRaw as List);
    final notifRaw = children['mem_repeated_notifications'];
    final repeatedNotifications = notifRaw == null
        ? null
        : List<MemNotificationEntity>.from(notifRaw as List);
    final relRaw = children['mem_relations'];
    final memRelations =
        relRaw == null ? null : List<MemRelationEntity>.from(relRaw as List);
    final latestActRaw = children['latest_act'];
    Act? latestAct;
    final latestList = latestActRaw as List?;
    if (latestList != null && latestList.isNotEmpty) {
      latestAct = (latestList.first as ActEntity).toDomain();
    }

    return MemEntity(
      row.id,
      row.name,
      row.doneAt,
      periodFromDb(
        notifyOn: row.notifyOn,
        notifyAt: row.notifyAt,
        endOn: row.endOn,
        endAt: row.endAt,
      ),
      memItems,
      row.createdAt,
      row.updatedAt,
      row.archivedAt,
      repeatedNotifications: repeatedNotifications,
      memRelations: memRelations,
      latestAct: latestAct,
    );
  }
}
