import 'package:mem/core/date_and_time_period.dart';

import 'entity_value.dart';

typedef MemId = int;

class Mem extends EntityValue {
  String name;
  DateTime? doneAt;
  DateAndTimePeriod? period;

  Mem({
    required this.name,
    this.doneAt,
    this.period,
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  bool isDone() => doneAt != null;

  @override
  String toString() => {
        'name': name,
        'doneAt': doneAt,
        'period': period,
      }.toString();

  // FIXME エレガントじゃない
  Mem copied() => Mem(
        name: name,
        doneAt: doneAt,
        period: period,
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
      );
}
