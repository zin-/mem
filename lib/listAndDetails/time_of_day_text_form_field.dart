import 'package:flutter/material.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger/i/api.dart';

class TimeOfDayTextFormField extends StatelessWidget {
  final TimeOfDay? timeOfDay;
  final Function(TimeOfDay? pickedTimeOfDay) onChanged;

  const TimeOfDayTextFormField({
    required this.timeOfDay,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {},
        () {
          return TextFormField(
            controller: TextEditingController(
              text: timeOfDay?.format(context) ?? '',
            ),
            decoration: InputDecoration(
              hintText: 'Cant show format. ${L10n().dev()}',
              suffixIcon: IconButton(
                onPressed: () => v(
                  {},
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
