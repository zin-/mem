import 'package:mem/core/entity_value.dart';
import 'package:mem/core/mem.dart';

import 'date_and_time_period.dart';

class Act extends EntityValue {
  final MemId memId;
  final DateAndTimePeriod period;

  @override
  int get id => super.id;

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
  String toString() => _toMap().toString();
}
