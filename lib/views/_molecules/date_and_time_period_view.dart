import 'package:flutter/material.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/_atoms/date_and_time_view.dart';

DateAndTimePeriodView? buildDateAndTimePeriodView(
    DateAndTimePeriod dateAndTimePeriod) {
  if (dateAndTimePeriod.start == null && dateAndTimePeriod.end == null) {
    return null;
  } else {
    return DateAndTimePeriodView(dateAndTimePeriod);
  }
}

class DateAndTimePeriodView extends StatelessWidget {
  final DateAndTimePeriod _dateAndTimePeriod;

  const DateAndTimePeriodView(this._dateAndTimePeriod, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_dateAndTimePeriod': _dateAndTimePeriod},
        () {
          final start = _dateAndTimePeriod.start;
          final startView =
              start == null ? const SizedBox.shrink() : DateAndTimeText(start);
          final end = _dateAndTimePeriod.end;
          final endView =
              end == null ? const SizedBox.shrink() : DateAndTimeText(end);

          return Row(
            children: [
              startView,
              const Text(' ~ '),
              endView,
            ],
          );
        },
      );
}
