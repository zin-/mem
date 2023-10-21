import 'package:mem/core/entity_value.dart';
import 'package:mem/framework/entity.dart';
import 'package:mem/framework/database_tuple_entity.dart';

import 'date_and_time/date_and_time_period.dart';

class ActV2 extends Entity {
  final int memId;
  final DateAndTimePeriod period;

  ActV2(this.memId, this.period);
}

class SavedActV2<I> extends ActV2 with SavedDatabaseTuple<I> {
  SavedActV2(super.memId, super.period);

  SavedActV2<I> copiedWith(DateAndTimePeriod period) => SavedActV2(
        memId,
        period,
      )
        ..id = id
        ..createdAt = createdAt
        ..updatedAt = updatedAt
        ..archivedAt = archivedAt;

  Act toV1() => Act(
        memId,
        period,
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
      );

  factory SavedActV2.fromV1(Act v1) => SavedActV2(v1.memId, v1.period)
    ..id = v1.id as I
    ..createdAt = v1.createdAt as DateTime
    ..updatedAt = v1.updatedAt
    ..archivedAt = v1.archivedAt;
}

class Act extends EntityValue {
  final int memId;
  final DateAndTimePeriod period;

  @override
  int? get id => super.id;

  Act(
    this.memId,
    this.period, {
    super.id,
    super.createdAt,
    super.updatedAt,
    super.archivedAt,
  });

  Map<String, dynamic> _toMap() => {
        'memId': memId,
        'period': period,
      };

  @override
  String toString() => _toMap().toString() + super.toString();

  Act copiedWith(DateAndTimePeriod period) => Act(
        memId,
        period,
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
      );
}
