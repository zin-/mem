import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

DateAndTime? _dateAndTime(DateTime? dateTime, {bool? isAllDay}) {
  if (dateTime == null) return null;
  return DateAndTime.from(
    dateTime,
    timeOfDay: isAllDay == true ? null : dateTime,
  );
}

SavedActEntityV1 savedAct({
  required int id,
  required int memId,
  DateTime? start,
  bool? startIsAllDay,
  DateTime? end,
  bool? endIsAllDay,
  DateTime? pausedAt,
  ActKind? actKind,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? archivedAt,
}) {
  final now = createdAt ?? DateTime(2024, 6, 1);
  return SavedActEntityV1.fromEntityV2(ActEntity(
    memId,
    _dateAndTime(start, isAllDay: startIsAllDay),
    _dateAndTime(end, isAllDay: endIsAllDay),
    pausedAt,
    id,
    now,
    updatedAt ?? now,
    archivedAt,
    actKind: actKind,
  ));
}

SavedActEntityV1 savedActFromDomain(
  Act act, {
  required int id,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? archivedAt,
}) {
  final now = createdAt ?? DateTime(2024, 6, 1);
  return SavedActEntityV1.fromEntityV2(ActEntity(
    act.memId,
    act.period?.start,
    act.period?.end,
    act.pausedAt,
    id,
    now,
    updatedAt ?? now,
    archivedAt,
    actKind: act.actKind,
  ));
}

MemEntity savedMem({
  required int id,
  required String name,
  DateTime? doneAt,
  DateTime? notifyOn,
  DateTime? notifyAt,
  DateTime? endOn,
  DateTime? endAt,
  Act? latestAct,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? archivedAt,
}) {
  final now = createdAt ?? DateTime.now();
  DateAndTimePeriod? period;
  if (notifyOn != null || endOn != null) {
    period = DateAndTimePeriod(
      start: notifyOn == null
          ? null
          : DateAndTime.from(notifyOn, timeOfDay: notifyAt),
      end: endOn == null ? null : DateAndTime.from(endOn, timeOfDay: endAt),
    );
  }
  return MemEntity(
    id,
    name,
    doneAt,
    period,
    null,
    now,
    updatedAt ?? now,
    archivedAt,
    latestAct: latestAct,
  );
}

MemEntity savedMemFromDomain(
  Mem mem, {
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? archivedAt,
  Act? latestAct,
}) =>
    savedMem(
      id: mem.id!,
      name: mem.name,
      doneAt: mem.doneAt,
      notifyOn: mem.period?.start,
      notifyAt: mem.period?.start?.isAllDay == true ? null : mem.period?.start,
      endOn: mem.period?.end,
      endAt: mem.period?.end?.isAllDay == true ? null : mem.period?.end,
      latestAct: latestAct ?? mem.latestAct,
      createdAt: createdAt,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
    );

SavedMemNotificationEntityV1 savedMemNotification({
  required int id,
  required int? memId,
  required MemNotificationType type,
  int? timeOfDaySeconds,
  required String message,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? archivedAt,
}) {
  final now = createdAt ?? DateTime.now();
  final entity = MemNotificationEntity(
    memId,
    type,
    timeOfDaySeconds,
    message,
    id,
    now,
    updatedAt ?? now,
    archivedAt,
  );
  if (memId == null) {
    return SavedMemNotificationEntityV1.fromRow(
      _NullableMemNotificationEntityRow(entity),
    );
  }
  return SavedMemNotificationEntityV1.fromEntityV2(entity);
}

class _NullableMemNotificationEntityRow {
  final MemNotificationEntity entity;

  _NullableMemNotificationEntityRow(this.entity);

  int get id => entity.id;
  int? get memId => entity.memId;
  String get type => entity.type.name;
  int? get timeOfDaySeconds => entity.time;
  String get message => entity.message;
  DateTime get createdAt => entity.createdAt;
  DateTime? get updatedAt => entity.updatedAt;
  DateTime? get archivedAt => entity.archivedAt;
}
