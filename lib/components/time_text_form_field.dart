import 'package:flutter/material.dart';
import 'package:flutter_picker/picker.dart';
import 'package:mem/logger/log_service.dart';

class TimeTextFormField extends StatelessWidget {
  final int? _secondsOfTime;
  final void Function(int? pickedSecondsOfTime) _onChanged;
  final Widget? _icon;

  const TimeTextFormField(
    this._secondsOfTime,
    this._onChanged,
    this._icon, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          int? hours;
          int? minutes;
          if (_secondsOfTime != null) {
            hours = (_secondsOfTime! ~/ 60 ~/ 60);
            minutes = (_secondsOfTime! ~/ 60 % 60);
          }
          return TextFormField(
            controller: TextEditingController(
              text:
                  hours != null && minutes != null ? '$hours h $minutes m' : '',
            ),
            decoration: InputDecoration(
              icon: _icon,
              hintText: 'h:m',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final picked = await Picker(
                    adapter: NumberPickerAdapter(data: [
                      NumberPickerColumn(
                        begin: 0,
                        end: 99,
                        suffix: const Text('h'),
                        initValue: hours,
                      ),
                      NumberPickerColumn(
                        begin: 0,
                        end: 59,
                        suffix: const Text('m'),
                        initValue: minutes,
                      ),
                    ]),
                  ).showModal(context);

                  if (picked != null) {
                    _onChanged(((picked[0] * 60) + picked[1]) * 60);
                  }
                },
              ),
            ),
          );
        },
        _secondsOfTime,
      );
}
