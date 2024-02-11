import 'package:flutter/material.dart';
import 'package:flutter_picker/picker.dart';
import 'package:mem/logger/log_service.dart';

class TimeTextFormField extends StatelessWidget {
  final int? _secondsOfTime;
  final void Function(int? pickedSecondsOfTime) _onChanged;

  const TimeTextFormField(
    this._secondsOfTime,
    this._onChanged, {
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
              hintText: 'h:m',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final picked = await Picker(
                    confirmText: 'OK',
                    adapter: NumberPickerAdapter(data: [
                      NumberPickerColumn(
                        begin: 0,
                        end: 99,
                        suffix: const Text('h'),
                        initValue: hours ?? 1,
                      ),
                      NumberPickerColumn(
                        begin: 0,
                        end: 59,
                        suffix: const Text('m'),
                        initValue: minutes ?? 0,
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
