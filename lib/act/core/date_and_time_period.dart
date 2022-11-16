import 'package:mem/domain/date_and_time.dart';

class DateAndTimePeriod {
  final DateAndTime? start;
  final DateAndTime? end;

  DateAndTimePeriod({this.start, this.end}) {
    assert(start != null || end != null);
    if (start != null && end != null) assert(start!.compareTo(end!) <= 0);
  }

  DateAndTimePeriod.startNow({bool allDay = false})
      : this(
          start: DateAndTime.now(allDay: allDay),
        );

  Map<String, dynamic> toMap() => {'start': start, 'end': end};

  @override
  String toString() => toMap().toString();
}
