import 'package:flutter/material.dart';
import 'package:mem/components/time_text_form_field.dart';
import 'package:mem/logger/log_service.dart';

class AfterActStartedNotificationView extends StatelessWidget {
  final int? _time;
  final String _message;
  final Function(int? time, String message) _onChanged;

  const AfterActStartedNotificationView(
    this._time,
    this._message,
    this._onChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => Card(
          child: Flex(
            direction: Axis.vertical,
            children: [
              Flex(
                direction: Axis.horizontal,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TimeTextFormField(
                      _time,
                      (pickedSecondsOfTime) => _onChanged(
                        pickedSecondsOfTime,
                        _message,
                      ),
                      const Icon(Icons.exposure_plus_1),
                    ),
                  ),
                  _time == null
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: () => _onChanged(null, _message),
                          icon: const Icon(Icons.clear),
                        ),
                ],
              ),
              TextFormField(
                initialValue: _message,
                onChanged: (value) => _onChanged(_time, value),
              ),
            ],
          ),
        ),
        [_time, _message],
      );
}
