import 'date_and_time.dart';

class DateAndTimePeriod implements Comparable<DateAndTimePeriod> {
  final DateAndTime? start;
  final DateAndTime? end;

  DateAndTimePeriod({this.start, this.end}) {
    assert(start != null || end != null);
    if (start != null && end != null) {
      assert(start!.compareTo(end!) <= 0);
    }
  }

  DateAndTimePeriod.startNow({bool allDay = false})
      : this(
          start: DateAndTime.now(allDay: allDay),
        );

  Map<String, dynamic> toMap() => {'start': start, 'end': end};

  @override
  String toString() => toMap().toString();

  @override
  int compareTo(DateAndTimePeriod other) {
    // TODO: implement compareTo
    //  -|
    // |-|
    // |----|
    // |-
    // |-------|
    //b   |---|
    //      -|
    //     |-|
    //     |---|
    //     |-
    //          -|
    //         |-|
    //         |-
    if (start != null) {
      if (other.start != null) {
        return start!.compareTo(other.start!);
      }
    }
    if (end != null) {
      if (other.end != null) {
        return end!.compareTo(other.end!);
      } else {}
    }

    return 0;
  }
}
