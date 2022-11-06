import 'package:mem/domain/date_and_time.dart';

class DateAndTimePeriod {
  final DateAndTime? start;
  final DateAndTime? end;

  DateAndTimePeriod({this.start, this.end}) {
    assert(start != null || end != null);
    if (start != null && end != null) assert(start!.compareTo(end!) <= 0);
  }

  DateAndTimePeriod.startNow({bool? allDay})
      : this(
          start: allDay == null
              ? DateAndTime.now()
              : DateAndTime.now(allDay: allDay),
        );
}
