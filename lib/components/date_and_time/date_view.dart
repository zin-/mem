import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/logger/log_service.dart';

final DateFormat _dateFormat = DateFormat.yMd();

String Function(DateTime dateTime) _buildFormatFunction(BuildContext context) {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);

  return localizations.formatCompactDate;
}

class DateText extends StatelessWidget {
  final DateTime _dateTime;
  final TextStyle? _style;

  const DateText(this._dateTime, {super.key, TextStyle? style})
      : _style = style;

  @override
  Widget build(BuildContext context) => v(
        () => Text(
          _buildFormatFunction(context)(_dateTime),
          style: _style,
        ),
        _dateTime,
      );
}

class DateTextFormField extends StatelessWidget {
  final DateTime? date;
  final Function(DateTime? pickedDate) onChanged;
  final DateTime? _firstDate;
  final DateTime? _lastDate;

  final maxDuration = const Duration(days: 1000000000000000000);

  const DateTextFormField(
    this.date,
    this.onChanged, {
    DateTime? firstDate,
    DateTime? lastDate,
    Key? key,
  })  : _firstDate = firstDate,
        _lastDate = lastDate,
        super(key: key);

  @override
  Widget build(BuildContext context) => v(
        () {
          return TextFormField(
            controller: TextEditingController(
              text: date == null ? '' : _buildFormatFunction(context)(date!),
            ),
            decoration: InputDecoration(
              hintText: _dateFormat.pattern,
              suffixIcon: IconButton(
                onPressed: () => v(
                  () async {
                    var initialDate = date ?? DateTime.now();
                    if (_lastDate?.compareTo(initialDate) == -1) {
                      initialDate = _lastDate!;
                    }
                    if (_firstDate?.compareTo(initialDate) == 1) {
                      initialDate = _firstDate!;
                    }

                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate:
                          _firstDate ?? initialDate.subtract(maxDuration),
                      lastDate: _lastDate ?? initialDate.add(maxDuration),
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
        {'date': date, 'firstDate': _firstDate, 'lastDate': _lastDate},
      );
}
