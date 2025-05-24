import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:mem/features/logger/log_service.dart';

Future<int?> showSecondsOfTimePicker(
  BuildContext context,
  int? secondsOfTime,
) =>
    v(
      () async {
        final hours = ((secondsOfTime ?? 3600) ~/ 60 ~/ 60);
        final minutes = ((secondsOfTime ?? 0) ~/ 60 % 60);

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

String formatSecondsOfTime(int? secondsOfTime) => v(
      () {
        if (secondsOfTime == null) {
          return "";
        } else {
          return '${secondsOfTime ~/ 60 ~/ 60} h ${secondsOfTime ~/ 60 % 60} m';
        }
      },
      {
        'secondsOfTime': secondsOfTime,
      },
    );
