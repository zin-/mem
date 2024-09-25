import 'date_and_time.dart';

abstract class DateAndTimePeriod implements Comparable<DateAndTimePeriod> {
  DateAndTime? get start;

  DateAndTime? get end;

  Duration get duration => Duration.zero;

  DateAndTimePeriod._();

  factory DateAndTimePeriod({DateAndTime? start, DateAndTime? end}) {
    if (start != null && end == null) {
      return _WithStartOnly(start);
    } else if (start == null && end != null) {
      return _WithEndOnly(end);
    } else if (start != null && end != null) {
      return WithStartAndEnd(start, end);
    }

    throw ArgumentError({
      'start': start,
      'end': end,
    }.toString());
  }

  factory DateAndTimePeriod.startNow({bool allDay = false}) {
    return _WithStartOnly(DateAndTime.now(allDay: allDay));
  }

  @override
  String toString() => {'start': start, 'end': end}.toString();

  DateAndTimePeriod copiedWith(DateAndTime? end) =>
      DateAndTimePeriod(start: start, end: end);

  static int compare(DateAndTimePeriod? a, DateAndTimePeriod? b) {
    if (a != null && b != null) {
      return a.compareTo(b);
    } else if (a == null && b == null) {
      return 0;
    } else {
      return a == null ? 1 : -1;
    }
  }

  int compareWithDateAndTime(DateTime? dateAndTime);
}

class _WithStartOnly extends DateAndTimePeriod
    implements Comparable<DateAndTimePeriod> {
  @override
  final DateAndTime start;

  @override
  Null get end => null;

  _WithStartOnly(this.start) : super._();

  @override
  int compareTo(DateAndTimePeriod other) {
    if (other is _WithStartOnly) {
      return start.compareTo(other.start);
    } else if (other is _WithEndOnly) {
      return start.isBefore(other.end) ? -1 : 1;
    } else {
      other as WithStartAndEnd;
      return -other.compareTo(this);
    }
  }

  @override
  int compareWithDateAndTime(DateTime? dateAndTime) =>
      dateAndTime == null ? 0 : start.compareTo(dateAndTime);
}

class _WithEndOnly extends DateAndTimePeriod
    implements Comparable<DateAndTimePeriod> {
  @override
  Null get start => null;

  @override
  final DateAndTime end;

  _WithEndOnly(this.end) : super._();

  @override
  int compareTo(DateAndTimePeriod other) {
    if (other is _WithStartOnly) {
      return end.isAfter(other.start) ? 1 : -1;
    } else if (other is _WithEndOnly) {
      return end.compareTo(other.end);
    } else {
      other as WithStartAndEnd;
      return -other.compareTo(this);
    }
  }

  @override
  int compareWithDateAndTime(DateTime? dateAndTime) =>
      dateAndTime == null ? 0 : end.compareTo(dateAndTime);
}

class WithStartAndEnd extends DateAndTimePeriod
    implements Comparable<DateAndTimePeriod> {
  @override
  final DateAndTime start;

  @override
  final DateAndTime end;

  @override
  Duration get duration => end.difference(start);

  WithStartAndEnd(this.start, this.end) : super._() {
    if (start.compareTo(end) > 0) {
      throw ArgumentError({
        'start': start,
        'end': end,
      }.toString());
    }
  }

  @override
  int compareTo(DateAndTimePeriod other) {
    if (other is _WithStartOnly) {
      return start.isAfter(other.start) ? 1 : -1;
    } else if (other is _WithEndOnly) {
      return end.isAfter(other.end) ? 1 : -1;
    } else {
      other as WithStartAndEnd;
      final c = start.compareTo(other.start);
      if (c != 0) {
        return c;
      } else {
        return end.compareTo(other.end);
      }
    }
  }

  @override
  int compareWithDateAndTime(DateTime? dateAndTime) =>
      dateAndTime == null ? 0 : end.compareTo(dateAndTime);
}
