import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

class TimeOfDayText extends StatelessWidget {
  final TimeOfDay _timeOfDay;

  const TimeOfDayText(
    this._timeOfDay, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => Text(_timeOfDay.format(context)),
        _timeOfDay,
      );
}

class TimeOfDayTextFormField extends StatelessWidget {
  final TimeOfDay? timeOfDay;
  final Function(TimeOfDay? pickedTimeOfDay) onChanged;
  final Widget? icon;

  const TimeOfDayTextFormField({
    required this.timeOfDay,
    required this.onChanged,
    Key? key,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        () {
          return TextFormField(
            controller: TextEditingController(
              text: timeOfDay?.format(context) ?? '',
            ),
            decoration: InputDecoration(
              icon: icon,
              suffixIcon: IconButton(
                onPressed: () => v(
                  () async {
                    final pickedTimeOfDay = await showTimePicker(
                      context: context,
                      initialTime: timeOfDay ?? TimeOfDay.now(),
                    );

                    onChanged(pickedTimeOfDay);
                  },
                ),
                icon: const Icon(Icons.access_time_outlined),
              ),
            ),
            keyboardType: TextInputType.datetime,
          );
        },
      );
}
