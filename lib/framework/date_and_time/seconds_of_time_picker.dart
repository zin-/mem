import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:mem/logger/log_service.dart';

Future<int?> showSecondsOfTimePicker(
  BuildContext context,
  int? secondsOfTime,
) =>
    v(
      () async {
        int hours;
        int minutes;
        if (secondsOfTime == null) {
          hours = 1;
          minutes = 0;
        } else {
          hours = (secondsOfTime ~/ 60 ~/ 60);
          minutes = (secondsOfTime ~/ 60 % 60);
        }

        final picked = await Picker(
          confirmText: 'OK',
          adapter: NumberPickerAdapter(
            data: [
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
            ],
          ),
        ).showModal<List<int>>(context);

        if (picked == null) {
          return null;
        } else {
          return ((picked[0] * 60) + picked[1]) * 60;
        }
      },
      {
        'context': context,
        'secondsOfTime': secondsOfTime,
      },
    );
