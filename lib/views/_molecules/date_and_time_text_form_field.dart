import 'package:flutter/material.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/_atoms/date_and_time_view.dart';

class DateAndTimeTextFormField extends StatelessWidget {
  final DateAndTime? _dateAndTime;
  final void Function(DateAndTime? pickedDateAndTime) _onChanged;

  const DateAndTimeTextFormField(
    this._dateAndTime,
    this._onChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        {'_dateAndTime': _dateAndTime},
        () {
          final dateAndTime = _dateAndTime;

          return Row(
            children: [
              Expanded(
                child: DateTextFormField(
                  dateAndTime,
                  (pickedDate) => _onChanged(DateAndTime.from(
                    pickedDate,
                    timeOfDay: dateAndTime?.timeOfDay,
                  )),
                ),
              ),
              dateAndTime == null || dateAndTime.isAllDay
                  ? const SizedBox.shrink()
                  : Expanded(
                      child: TimeOfDayTextFormField(
                        dateAndTime.timeOfDay,
                        (pickedTimeOfDay) {
                          _onChanged(DateAndTime.from(
                            dateAndTime.dateTime,
                            timeOfDay: pickedTimeOfDay,
                          ));
                        },
                      ),
                    ),
              dateAndTime == null
                  ? const SizedBox.shrink()
                  : Switch(
                      value: dateAndTime.isAllDay,
                      onChanged: (allDay) => _onChanged(DateAndTime.from(
                        dateAndTime.dateTime,
                        timeOfDay: allDay ? null : TimeOfDay.now(),
                      )),
                    ),
              dateAndTime == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: () => _onChanged(null),
                      icon: const Icon(Icons.clear),
                    ),
            ],
          );
        },
      );
}