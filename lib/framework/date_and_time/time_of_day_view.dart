import 'package:flutter/material.dart';
import 'package:mem/features/logger/log_service.dart';

class TimeOfDayText extends StatelessWidget {
  final TimeOfDay _timeOfDay;
  final TextStyle? _style;

  const TimeOfDayText(this._timeOfDay, {super.key, TextStyle? style})
      : _style = style;

  @override
  Widget build(BuildContext context) => v(
        () => Text(
          _timeOfDay.format(context),
          style: _style,
        ),
        _timeOfDay,
      );
}

class TimeOfDayTextFormField extends StatefulWidget {
  final TimeOfDay? timeOfDay;
  final Function(TimeOfDay? pickedTimeOfDay) onChanged;
  final Widget? icon;

  const TimeOfDayTextFormField({
    required this.timeOfDay,
    required this.onChanged,
    this.icon,
    super.key,
  });

  @override
  State<TimeOfDayTextFormField> createState() => _TimeOfDayTextFormFieldState();
}

class _TimeOfDayTextFormFieldState extends State<TimeOfDayTextFormField> {
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
  void didUpdateWidget(covariant TimeOfDayTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeOfDay != widget.timeOfDay) {
      _syncControllerText();
    }
  }

  void _syncControllerText() {
    if (!mounted) return;
    final text = widget.timeOfDay?.format(context) ?? '';
    if (_controller.text != text) {
      _controller.text = text;
    }
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
              icon: widget.icon,
              suffixIcon: IconButton(
                onPressed: () => v(
                  () async {
                    final pickedTimeOfDay = await showTimePicker(
                      context: context,
                      initialTime: widget.timeOfDay ?? TimeOfDay.now(),
                    );

                    if (!mounted) return;
                    if (pickedTimeOfDay != null) widget.onChanged(pickedTimeOfDay);
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
