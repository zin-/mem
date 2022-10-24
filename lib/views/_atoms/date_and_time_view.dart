import 'package:flutter/material.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';

class DateAndTimeText extends StatelessWidget {
  final DateAndTime _dateAndTime;

  const DateAndTimeText(this._dateAndTime, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_dateAndTime': _dateAndTime},
        () {
          final l10n = L10n(context);

          return Text(
            _dateAndTime.isAllDay
                ? l10n.formatDate(_dateAndTime)
                : l10n.formatDateTime(_dateAndTime),
          );
        },
      );
}

const maxDuration = Duration(days: 1000000000000000000);

class DateTextFormField extends StatelessWidget {
  final DateTime? _date;
  final void Function(DateTime pickedDate) _onChanged;

  const DateTextFormField(
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
            controller: TextEditingController(
              text: date == null ? '' : l10n.formatDate(date),
            ),
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

                  if (pickedDate != null) {
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

class TimeOfDayTextFormField extends StatelessWidget {
  final TimeOfDay? _timeOfDay;
  final void Function(TimeOfDay pickedTimeOfDay) _onChanged;

  const TimeOfDayTextFormField(this._timeOfDay, this._onChanged, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_timeOfDay': _timeOfDay},
        () {
          final l10n = L10n(context);
          final timeOfDay = _timeOfDay;

          return TextFormField(
            controller: TextEditingController(
              text: timeOfDay == null ? '' : l10n.formatTimeOfDay(timeOfDay),
            ),
            decoration: InputDecoration(
              suffixIcon: IconButton(
                onPressed: () async {
                  final pickedTimeOfDay = await showTimePicker(
                    context: context,
                    initialTime: _timeOfDay ?? TimeOfDay.now(),
                  );

                  if (pickedTimeOfDay != null) {
                    _onChanged(pickedTimeOfDay);
                  }
                },
                icon: const Icon(Icons.access_time),
              ),
            ),
          );
        },
      );
}