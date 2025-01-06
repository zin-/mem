import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:mem/logger/log_service.dart';

Future<List<int>?> showSecondsOfTimePicker(
  BuildContext context,
  int? secondsOfTime,
) =>
    v(
      () async {
        int? hours;
        int? minutes;
        if (secondsOfTime != null) {
          hours = (secondsOfTime ~/ 60 ~/ 60);
          minutes = (secondsOfTime ~/ 60 % 60);
        }

        return await Picker(
          confirmText: 'OK',
          adapter: NumberPickerAdapter(
            data: [
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
            ],
          ),
        ).showModal<List<int>>(context);
      },
      {
        'context': context,
        'secondsOfTime': secondsOfTime,
      },
    );
