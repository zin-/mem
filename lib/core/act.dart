import 'package:mem/core/entity_value.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

import 'date_and_time/date_and_time_period.dart';

class ActV2 extends Entity {
  final int memId;
  final DateAndTimePeriod period;

  ActV2(this.memId, this.period);
}

class SavedActV2<I> extends ActV2 with SavedDatabaseTupleMixin<I> {
  SavedActV2(super.memId, super.period);

  SavedActV2<I> copiedWith(DateAndTimePeriod Function()? period) => SavedActV2(
        memId,
        period == null ? this.period : period(),
      )
        ..id = id
        ..createdAt = createdAt
        ..updatedAt = updatedAt
        ..archivedAt = archivedAt;
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
