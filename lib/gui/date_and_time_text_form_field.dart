import 'package:flutter/material.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/gui/date_text_form_field.dart';
import 'package:mem/logger/log_service_v2.dart';

import 'time_of_day_text_form_field.dart';

class DateAndTimeTextFormFieldV2 extends StatelessWidget {
  final DateAndTime? _dateAndTime;
  final void Function(DateAndTime? pickedDateAndTime) _onChanged;
  final DateAndTimePeriod? _selectableRange;

  const DateAndTimeTextFormFieldV2(
    this._dateAndTime,
    this._onChanged, {
    super.key,
    DateAndTimePeriod? selectableRange,
  }) : _selectableRange = selectableRange;

  @override
  Widget build(BuildContext context) => v(
        () {
          final isAllDay =
              _dateAndTime == null ? true : _dateAndTime?.isAllDay ?? true;

          return Row(
            children: [
              Expanded(
                  child: DateTextFormField(
                date: _dateAndTime,
                onChanged: (pickedDate) => v(
                  () {
                    if (pickedDate != null) {
                      if (isAllDay) {
                        _onChanged(DateAndTime.fromV2(pickedDate));
                      } else {
                        _onChanged(DateAndTime.fromV2(
                          pickedDate,
                          timeOfDay: _dateAndTime,
                        ));
                      }
                    }
                  },
                  pickedDate,
                ),
                firstDate: _selectableRange?.start,
                lastDate: _selectableRange?.end,
              )),
              isAllDay
                  ? const SizedBox.shrink()
                  : Expanded(
                      child: TimeOfDayTextFormField(
                        timeOfDay: TimeOfDay.fromDateTime(
                          _dateAndTime ?? DateAndTime.now(),
                        ),
                        onChanged: (timeOfDay) {
                          if (timeOfDay != null) {
                            final _ = _dateAndTime ?? DateTime.now();
                            _onChanged(DateAndTime(
                              _.year,
                              _.month,
                              _.day,
                              timeOfDay.hour,
                              timeOfDay.minute,
                            ));
                          }
                        },
                      ),
                    ),
              Switch(
                value: isAllDay,
                onChanged: (value) => v(
                  () async {
                    if (isAllDay) {
                      final pickedTimeOfDay = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTimeOfDay != null) {
                        _onChanged(DateAndTime.from(
                          _dateAndTime ?? DateAndTime.now(),
                          timeOfDay: pickedTimeOfDay,
                          allDay: false,
                        ));
                      }
                    } else {
                      _onChanged(DateAndTime.fromV2(
                        _dateAndTime!,
                        timeOfDay: null,
                      ));
                    }
                  },
                  value,
                ),
              ),
              _dateAndTime == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: () => _onChanged(null),
                      icon: const Icon(Icons.clear),
                    ),
            ],
          );
        },
        {_dateAndTime, _selectableRange},
      );
}
