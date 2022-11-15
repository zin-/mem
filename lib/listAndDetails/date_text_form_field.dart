import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/logger/i/api.dart';

class DateTextFormField extends StatelessWidget {
  final DateTime? date;
  final Function(DateTime? pickedDate) onChanged;

  final DateFormat _dateFormat = DateFormat.yMd();

  DateTextFormField({
    required this.date,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {'date': date},
        () {
          return TextFormField(
            controller: TextEditingController(
              text: date == null ? '' : _dateFormat.format(date!),
            ),
            decoration: InputDecoration(
              hintText: _dateFormat.pattern,
              suffixIcon: IconButton(
                onPressed: () => v(
                  {},
                  () async {
                    final currentDate = DateTime.now();
                    final initialDate = date ?? currentDate;
                    const maxDuration = Duration(days: 1000000000000000000);

                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: initialDate.subtract(maxDuration),
                      lastDate: initialDate.add(maxDuration),
                    );

                    onChanged(pickedDate);
                  },
                ),
                icon: const Icon(Icons.calendar_month),
              ),
            ),
            keyboardType: TextInputType.datetime,
          );
        },
      );
}
