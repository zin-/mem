import 'package:flutter/material.dart';
import 'package:mem/components/date_and_time/date_view.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';

class DateAndTimeText extends StatelessWidget {
  final DateAndTime _dateAndTime;
  final TextStyle? _style;

  const DateAndTimeText(this._dateAndTime, {super.key, TextStyle? style})
      : _style = style;

  @override
  Widget build(BuildContext context) {
    if (_dateAndTime.isAllDay) {
      return DateText(_dateAndTime);
    } else {
      return Flex(
        direction: Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          DateText(_dateAndTime, style: _style),
          const Text(' '),
          TimeOfDayText(TimeOfDay.fromDateTime(_dateAndTime), style: _style),
        ],
      );
    }
  }
}
