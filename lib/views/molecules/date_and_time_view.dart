import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/l10n.dart';

final _dateFormat = DateFormat.yMd(L10n().local);
final _dateAndTimeFormat = DateFormat(_dateFormat.pattern).add_Hm();

class DateAndTimeText extends Text {
  DateAndTimeText(DateTime date, TimeOfDay? timeOfDay, {super.key})
      : super(timeOfDay == null
            ? _dateFormat.format(date)
            : _dateAndTimeFormat.format(
                date.add(Duration(
                  hours: timeOfDay.hour,
                  minutes: timeOfDay.minute,
                )),
              ));
}
