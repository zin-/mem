import 'package:mem/core/entity_value.dart';
import 'package:mem/core/mem.dart';

import 'date_and_time/date_and_time_period.dart';

class Act extends EntityValue {
  final MemId memId;
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

  Act.copyWith(Act base, {DateAndTimePeriod? period})
      : memId = base.memId,
        period = period ?? base.period,
        super(
          id: base.id,
          createdAt: base.createdAt,
          updatedAt: base.updatedAt,
          archivedAt: base.archivedAt,
        );

  ActIdentifier get identifier => ActIdentifier(id!, memId);
}

class ActIdentifier {
  final int id;
  final int memId;

  ActIdentifier(this.id, this.memId);

  @override
  int get hashCode => Object.hash(id, memId);

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;
}
