import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/view/synced_text_editing_controller.dart';

final DateFormat _dateFormat = DateFormat.yMd();

const _datePickerMaxDuration = Duration(days: 1000000000000000000);

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

class DateTextFormField extends StatefulWidget {
  final DateTime? date;
  final Function(DateTime? pickedDate) onChanged;
  final DateTime? _firstDate;
  final DateTime? _lastDate;

  const DateTextFormField(
    this.date,
    this.onChanged, {
    DateTime? firstDate,
    DateTime? lastDate,
    super.key,
  })  : _firstDate = firstDate,
        _lastDate = lastDate;

  @override
  State<DateTextFormField> createState() => _DateTextFormFieldState();
}

class _DateTextFormFieldState extends State<DateTextFormField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllerText();
  }

  @override
  void didUpdateWidget(covariant DateTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _syncControllerText(postFrame: true);
    }
  }

  void _syncControllerText({bool postFrame = false}) {
    syncTextEditingController(
      controller: _controller,
      mounted: mounted,
      postFrame: postFrame,
      buildText: () => widget.date == null
          ? ''
          : _buildFormatFunction(context, true)(widget.date!),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => v(
        () {
          return TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: _dateFormat.pattern,
              suffixIcon: IconButton(
                onPressed: () => v(
                  () async {
                    var initialDate = widget.date ?? DateTime.now();
                    if (widget._lastDate?.compareTo(initialDate) == -1) {
                      initialDate = widget._lastDate!;
                    }
                    if (widget._firstDate?.compareTo(initialDate) == 1) {
                      initialDate = widget._firstDate!;
                    }

                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: widget._firstDate ??
                          initialDate.subtract(_datePickerMaxDuration),
                      lastDate: widget._lastDate ??
                          initialDate.add(_datePickerMaxDuration),
                    );

                    if (!context.mounted) return;
                    widget.onChanged(pickedDate);
                  },
                ),
                icon: const Icon(Icons.calendar_month),
              ),
            ),
            keyboardType: TextInputType.datetime,
          );
        },
        {
          'date': widget.date,
          'firstDate': widget._firstDate,
          'lastDate': widget._lastDate,
        },
      );
}
