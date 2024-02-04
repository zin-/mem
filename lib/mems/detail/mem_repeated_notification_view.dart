import 'package:flutter/material.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/logger/log_service.dart';

const keyMemRepeatedNotification = Key("mem-repeated-notification");

class MemRepeatedNotificationView extends StatelessWidget {
  final TimeOfDay? _notifyAt;
  final Function(TimeOfDay? updating) _onChanged;

  const MemRepeatedNotificationView(
    this._notifyAt,
    this._onChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => Flex(
          key: keyMemRepeatedNotification,
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TimeOfDayTextFormField(
                timeOfDay: _notifyAt,
                onChanged: _onChanged,
                icon: const Icon(Icons.repeat),
              ),
            ),
            _notifyAt == null
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: () => _onChanged(null),
                    icon: const Icon(Icons.clear),
                  ),
          ],
        ),
        {"_notifyAt": _notifyAt},
      );
}
