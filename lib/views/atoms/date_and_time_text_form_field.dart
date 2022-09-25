import 'package:flutter/material.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/atoms/date_text_form_field.dart';
import 'package:mem/views/atoms/time_of_day_text_form_field.dart';

class DateAndTimeTextFormField extends StatelessWidget {
  final DateTime? date;
  final Function(DateTime? pickedDate) onDateChanged;
  final TimeOfDay? timeOfDay;
  final Function(TimeOfDay? pickedtimeOfDay) onTimeOfDayChanged;

  const DateAndTimeTextFormField({
    required this.date,
    required this.onDateChanged,
    required this.timeOfDay,
    required this.onTimeOfDayChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'date': date, 'timeOfDay': timeOfDay},
        () {
          final allDay = timeOfDay == null;

          return Row(
            children: [
              Expanded(
                child: DateTextFormField(
                  date: date,
                  onChanged: onDateChanged,
                ),
              ),
              allDay
                  ? const SizedBox.shrink()
                  : Expanded(
                      child: TimeOfDayTextFormField(
                        timeOfDay: timeOfDay,
                        onChanged: onTimeOfDayChanged,
                      ),
                    ),
              Switch(
                value: allDay,
                onChanged: (value) {
                  if (value) {
                    onTimeOfDayChanged(null);
                  }
                },
              ),
              date == null && timeOfDay == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: () {
                        onDateChanged(null);
                        onTimeOfDayChanged(null);
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ],
          );
        },
      );
}
