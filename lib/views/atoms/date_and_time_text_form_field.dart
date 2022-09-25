import 'package:flutter/material.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/atoms/date_text_form_field.dart';
import 'package:mem/views/atoms/time_of_day_text_form_field.dart';

class DateAndTimeTextFormField extends StatelessWidget {
  final DateTime? _date;
  final TimeOfDay? _timeOfDay;

  const DateAndTimeTextFormField({
    required DateTime? date,
    required TimeOfDay? timeOfDay,
    Key? key,
  })  : _date = date,
        _timeOfDay = timeOfDay,
        super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'_date': _date, '_timeOfDay': _timeOfDay},
        () {
          final allDay = _timeOfDay == null;

          return Row(
            children: [
              Expanded(
                child: DateTextFormField(
                  date: _date,
                  onChanged: (a) {},
                ),
              ),
              allDay
                  ? const SizedBox.shrink()
                  : Expanded(
                      child: TimeOfDayTextFormField(
                        timeOfDay: _timeOfDay,
                        onChanged: (a) {},
                      ),
                    ),
              Switch(
                value: allDay,
                onChanged: (value) {},
              ),
              _date == null && _timeOfDay == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.clear),
                    ),
            ],
          );
        },
      );
}
