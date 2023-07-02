import 'package:flutter/material.dart';
import 'package:mem/component/view/date_and_time/date_view.dart';
import 'package:mem/component/view/date_and_time/time_of_day_view.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';

class DateAndTimeText extends StatelessWidget {
  final DateAndTime _dateAndTime;

  const DateAndTimeText(
    this._dateAndTime, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (_dateAndTime.isAllDay) {
      return DateText(_dateAndTime);
    } else {
      return Flex(
        direction: Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          DateText(_dateAndTime),
          const Text(' '),
          TimeOfDayText(TimeOfDay.fromDateTime(_dateAndTime)),
        ],
      );
    }
  }
}
