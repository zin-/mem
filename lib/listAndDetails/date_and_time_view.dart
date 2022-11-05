import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/domain/date_and_time.dart';
import 'package:mem/l10n.dart';

final _dateFormat = DateFormat.yMd(L10n().local);
final _dateAndTimeFormat = DateFormat(_dateFormat.pattern).add_Hm();

class DateAndTimeText extends Text {
  DateAndTimeText(
    DateAndTime dateAndTime, {
    super.key,
    super.style,
  }) : super(
          dateAndTime.isAllDay
              ? _dateFormat.format(dateAndTime.dateTime)
              : _dateAndTimeFormat.format(dateAndTime),
        );
}
