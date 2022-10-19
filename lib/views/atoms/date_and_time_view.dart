import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';

@Deprecated('use L10n')
DateFormat buildDateFormat(BuildContext context) =>
    DateFormat.yMd(L10n(context).locale);

@Deprecated('use L10n')
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

const maxDuration = Duration(days: 1000000000000000000);

class DateTextFormFieldV2 extends StatelessWidget {
  final DateTime? _date;
  final Function(DateTime? pickedDate) _onChanged;

  DateTextFormFieldV2(
    this._date,
    this._onChanged, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {'_date': _date},
        () {
          final l10n = L10n(context);
          final date = _date;

          return TextFormField(
            initialValue: date == null ? '' : l10n.formatDate(date),
            decoration: InputDecoration(
              hintText: l10n.dateHelpText,
              suffixIcon: IconButton(
                onPressed: () async {
                  final initialDate = date ?? DateTime.now();

                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: initialDate.subtract(maxDuration),
                    lastDate: initialDate.add(maxDuration),
                  );

                  if (_date != pickedDate) {
                    _onChanged(pickedDate);
                  }
                },
                icon: const Icon(Icons.calendar_month),
              ),
            ),
          );
        },
      );
}
