import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/logger.dart';

final _dateFormat = DateFormat.yMd();
final _dateAndTimeFormat = _dateFormat.add_Hm();

class DateAndTimeText extends StatelessWidget {
  final DateTime? _date;
  final TimeOfDay? _timeOfDay;

  const DateAndTimeText(this._date, this._timeOfDay, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_date': _date, '_timeOfDay': _timeOfDay},
        () {
          final date = _date;
          if (date == null) return const SizedBox.shrink();

          final timeOfDay = _timeOfDay;
          if (timeOfDay == null) return Text(_dateFormat.format(date));

          return Text(
            _dateAndTimeFormat.format(
              date.add(
                Duration(
                  hours: timeOfDay.hour,
                  minutes: timeOfDay.minute,
                ),
              ),
            ),
          );
        },
      );
}
