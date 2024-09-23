class DateAndTime extends DateTime {
  bool isAllDay = false;

  DateAndTime(int year,
      [int month = 1,
      int day = 1,
      int? hour,
      int? minute,
      int? second,
      int? millisecond,
      int? microsecond])
      : isAllDay = hour == null &&
            minute == null &&
            second == null &&
            millisecond == null &&
            microsecond == null,
        super(
          year,
          month,
          day,
          hour ?? 0,
          minute ?? 0,
          second ?? 0,
          millisecond ?? 0,
          microsecond ?? 0,
        );

  DateAndTime.from(
    DateTime dateTime, {
    DateTime? timeOfDay,
  }) : this(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          timeOfDay?.hour,
          timeOfDay?.minute,
          timeOfDay?.second,
          timeOfDay?.millisecond,
          timeOfDay?.microsecond,
        );

  factory DateAndTime.now({bool allDay = false}) {
    final now = DateTime.now();
    return DateAndTime.from(
      now,
      timeOfDay: allDay ? null : now,
    );
  }

  DateTime get dateTime => DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
      );

  @override
  DateAndTime add(Duration duration) {
    final added = super.add(duration);

    return DateAndTime(
      added.year,
      added.month,
      added.day,
      isAllDay ? null : added.hour,
      isAllDay ? null : added.minute,
    );
  }

  @override
  DateAndTime subtract(Duration duration) {
    final subtracted = super.subtract(duration);

    return DateAndTime(
      subtracted.year,
      subtracted.month,
      subtracted.day,
      isAllDay ? null : subtracted.hour,
      isAllDay ? null : subtracted.minute,
    );
  }

  Map<String, dynamic> toMap() => {
        '_': super.toString(),
        'isAllDay': isAllDay,
      };

  @override
  String toString() => toMap().toString();

  @override
  int compareTo(DateTime other) {
    if (other is DateAndTime && (isAllDay || other.isAllDay)) {
      return DateTime(year, month, day)
          .compareTo(DateTime(other.year, other.month, other.day));
    }

    return super.compareTo(other);
  }
}
