import 'package:mem/act/domain/date_and_time_period.dart';

class Act {
  final DateAndTimePeriod period;

  Act(this.period);

  Map<String, dynamic> toMap() => {
        'period': period,
      };

  @override
  String toString() => toMap().toString();
}
