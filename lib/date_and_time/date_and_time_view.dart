import 'package:flutter/material.dart';
import 'package:mem/date_and_time/date_view.dart';
import 'package:mem/date_and_time/time_of_day_view.dart';
import 'package:mem/date_and_time/date_and_time.dart';

class DateAndTimeText extends StatelessWidget {
  final DateAndTime _dateAndTime;

  // FIXME boolではなくformat関数を渡すべき
  final bool _showDate;
  final bool _showTime;
  final TextStyle? _style;

  const DateAndTimeText(
    this._dateAndTime, {
    super.key,
    showDate = true,
    showTime = true,
    TextStyle? style,
  })  : _showDate = showDate,
        _showTime = showTime,
        _style = style;

  @override
  Widget build(BuildContext context) {
    if (_dateAndTime.isAllDay) {
      return DateText(_dateAndTime, _showDate, style: _style);
    } else if (_showTime) {
      return Flex(
        direction: Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          DateText(_dateAndTime, _showDate, style: _style),
          const Text(' '),
          TimeOfDayText(TimeOfDay.fromDateTime(_dateAndTime), style: _style),
        ],
      );
    } else {
      return TimeOfDayText(TimeOfDay.fromDateTime(_dateAndTime), style: _style);
    }
  }
}
