import 'package:flutter/material.dart';
import 'package:mem/components/date_and_time/date_view.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

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

          return Flex(
            direction: Axis.horizontal,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: DateTextFormField(
                _dateAndTime,
                (pickedDate) => v(
                  () {
                    if (pickedDate != null) {
                      if (isAllDay) {
                        _onChanged(DateAndTime.from(pickedDate));
                      } else {
                        _onChanged(DateAndTime.from(
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
                              _.second,
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
                        final dateAndTime = _dateAndTime ?? DateAndTime.now();
                        _onChanged(DateAndTime.from(
                          dateAndTime,
                          timeOfDay: DateAndTime(
                            dateAndTime.year,
                            dateAndTime.month,
                            dateAndTime.minute,
                            pickedTimeOfDay.hour,
                            pickedTimeOfDay.minute,
                            dateAndTime.second,
                          ),
                        ));
                      }
                    } else {
                      _onChanged(DateAndTime.from(
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
