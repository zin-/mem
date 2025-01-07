import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/seconds_of_time_picker.dart';
import 'package:mem/logger/log_service.dart';

class TimeTextFormField extends StatelessWidget {
  final int? secondsOfTime;
  final void Function(int? pickedSecondsOfTime) _onChanged;

  const TimeTextFormField(
    this.secondsOfTime,
    this._onChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          int? hours;
          int? minutes;
          if (secondsOfTime != null) {
            hours = (secondsOfTime! ~/ 60 ~/ 60);
            minutes = (secondsOfTime! ~/ 60 % 60);
          }
          return TextFormField(
            controller: TextEditingController(
              text:
                  hours != null && minutes != null ? '$hours h $minutes m' : '',
            ),
            decoration: InputDecoration(
              hintText: 'h:m',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final picked = await showSecondsOfTimePicker(
                    context,
                    secondsOfTime,
                  );

                  if (picked != null) {
                    _onChanged(picked);
                  }
                },
              ),
            ),
          );
        },
        secondsOfTime,
      );
}
