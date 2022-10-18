import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';

DateFormat buildDateFormat(BuildContext context) =>
    DateFormat.yMd(L10n(context).locale);

DateFormat buildDateAndTimeFormat(BuildContext context) =>
    buildDateFormat(context).add_Hm();

class DateAndTimeText extends StatelessWidget {
  final DateAndTime _dateAndTime;

  const DateAndTimeText(this._dateAndTime, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_dateAndTime': _dateAndTime},
        () => Text(
          _dateAndTime.isAllDay
              ? buildDateFormat(context).format(_dateAndTime)
              : buildDateAndTimeFormat(context).format(_dateAndTime),
        ),
      );
}
