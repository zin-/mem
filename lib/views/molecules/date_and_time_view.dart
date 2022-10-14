import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';

DateFormat buildDateFormat(BuildContext context) =>
    DateFormat.yMd(L10n(context).locale);

DateFormat buildDateAndTimeFormat(BuildContext context) =>
    buildDateFormat(context).add_Hm();

class DateAndTimeText extends StatelessWidget {
  final DateTime _date;
  final TimeOfDay? _timeOfDay;

  const DateAndTimeText(this._date, this._timeOfDay, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_date': _date, '_timeOfDay': _timeOfDay},
        () {
          final timeOfDay = _timeOfDay;

          return Text(timeOfDay == null
              ? buildDateFormat(context).format(_date)
              : buildDateAndTimeFormat(context).format(_date.add(Duration(
                  hours: timeOfDay.hour,
                  minutes: timeOfDay.minute,
                ))));
        },
      );
}
