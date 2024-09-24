import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/logger/log_service.dart';

final DateFormat _dateFormat = DateFormat.yMd();

String Function(DateTime dateTime) _buildFormatFunction(
  BuildContext context,
  bool showDate,
) {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);

  return showDate
      ? localizations.formatCompactDate
      : localizations.formatMonthYear;
}

class DateText extends StatelessWidget {
  final DateTime _dateTime;
  final bool _showDate;
  final TextStyle? _style;

  const DateText(this._dateTime, this._showDate, {super.key, TextStyle? style})
      : _style = style;

  @override
  Widget build(BuildContext context) => v(
        () => Text(
          _buildFormatFunction(context, _showDate)(_dateTime),
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
    super.key,
  })  : _firstDate = firstDate,
        _lastDate = lastDate;

  @override
  Widget build(BuildContext context) => v(
        () {
          return TextFormField(
            controller: TextEditingController(
              text: date == null
                  ? ''
                  : _buildFormatFunction(context, true)(date!),
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
