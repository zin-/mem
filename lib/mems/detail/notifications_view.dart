import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/components/time_text_form_field.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/core/date_and_time/time_of_day.dart' as core;

class NotificationsWidget extends ConsumerWidget {
  final int? _memId;

  const NotificationsWidget(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadMemNotificationsByMemId(_memId),
          (loaded) => _NotificationsWidgetComponent(
            ref.watch(memDetailProvider(_memId)).notifications!,
            (current) => (time, message) => ref
                    .read(memNotificationsByMemIdProvider(_memId).notifier)
                    .upsertAll(
                  [
                    MemNotificationV2.fromV1(current.copyWith(time, message)),
                  ],
                  (tmp, item) =>
                      tmp.type == item.type &&
                      (tmp is SavedMemNotificationV2 &&
                              item is SavedMemNotificationV2
                          ? tmp.id == item.id
                          : true),
                ),
          ),
        ),
        _memId,
      );
}

class _NotificationsWidgetComponent extends StatelessWidget {
  final List<MemNotification> _notifications;
  final Function(int? pickedTimeOfDay, String message) Function(
      MemNotification current) _onChanged;

  const _NotificationsWidgetComponent(this._notifications, this._onChanged);

  @override
  Widget build(BuildContext context) => v(
        () => Column(
          children: _notifications.map((e) {
            switch (e.type) {
              case MemNotificationType.repeat:
                return _RepeatedNotificationWidgetComponent(
                  e.time == null
                      ? null
                      : core.TimeOfDay.fromSeconds(e.time!).convert(),
                  (pickedTimeOfDay) => _onChanged(e)(
                    pickedTimeOfDay?.convert().toSeconds(),
                    e.message,
                  ),
                );
              case MemNotificationType.afterActStarted:
                return _AfterActStartedNotificationWidgetComponent(
                  e.time,
                  e.message,
                  _onChanged(e),
                );
            }
          }).toList(),
        ),
        _notifications,
      );
}

class _RepeatedNotificationWidgetComponent extends StatelessWidget {
  final TimeOfDay? _notifyAt;
  final Function(TimeOfDay? pickedTimeOfDay) _onChanged;

  const _RepeatedNotificationWidgetComponent(this._notifyAt, this._onChanged);

  @override
  Widget build(BuildContext context) => v(
        () => Flex(
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
        _notifyAt,
      );
}

class _AfterActStartedNotificationWidgetComponent extends StatelessWidget {
  final int? _time;
  final String _message;
  final Function(int? time, String message) _onChanged;

  const _AfterActStartedNotificationWidgetComponent(
    this._time,
    this._message,
    this._onChanged,
  );

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

extension on core.TimeOfDay {
  TimeOfDay convert() => TimeOfDay(hour: hour, minute: minute);
}

extension on TimeOfDay {
  core.TimeOfDay convert() => core.TimeOfDay(hour, minute);
}
