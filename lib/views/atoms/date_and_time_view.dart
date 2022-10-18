import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';

DateFormat buildDateFormat(BuildContext context) =>
    DateFormat.yMd(L10n(context).locale);

DateFormat buildDateAndTimeFormat(BuildContext context) =>
    buildDateFormat(context).add_Hm();

class DateAndTimeText extends StatelessWidget {
  final DateAndTime _dateAndTime;

  const DateAndTimeText(this._dateAndTime, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_dateAndTime': _dateAndTime},
        () => Text(
          _dateAndTime.isAllDay
              ? buildDateFormat(context).format(_dateAndTime)
              : buildDateAndTimeFormat(context).format(_dateAndTime),
        ),
      );
}

class DateTextFormFieldV2 extends StatelessWidget {
  final DateTime? date;

  // final Function(DateTime? pickedDate) onChanged;

  // final DateFormat _dateFormat = DateFormat.yMd();

  DateTextFormFieldV2({
    required this.date,
    // required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {'date': date},
        () {
          return TextFormField();
          // return TextFormField(
          //   controller: TextEditingController(
          //     text: date == null ? '' : _dateFormat.format(date!),
          //   ),
          //   decoration: InputDecoration(
          //     hintText: _dateFormat.pattern,
          //     suffixIcon: IconButton(
          //       onPressed: () => v(
          //         {},
          //         () async {
          //           final currentDate = DateTime.now();
          //           final initialDate = date ?? currentDate;
          //           const maxDuration = Duration(days: 1000000000000000000);
          //
          //           final pickedDate = await showDatePicker(
          //             context: context,
          //             initialDate: initialDate,
          //             firstDate: initialDate.subtract(maxDuration),
          //             lastDate: initialDate.add(maxDuration),
          //           );
          //
          //           onChanged(pickedDate);
          //         },
          //       ),
          //       icon: const Icon(Icons.calendar_month),
          //     ),
          //   ),
          //   keyboardType: TextInputType.datetime,
          // );
        },
      );
}
