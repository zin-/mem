import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/date_and_time/time_text_form_field.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_notification_entity.dart';

const keyMemAfterActStartedNotification =
    Key("mem-after-act-started-notification");

class AfterActStartedNotificationView extends ConsumerWidget {
  final int? _memId;

  const AfterActStartedNotificationView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final time = ref.watch(
              memAfterActStartedNotificationByMemIdProvider(_memId)
                  .select((value) => value.time));
          final message = ref.watch(
              memAfterActStartedNotificationByMemIdProvider(_memId)
                  .select((value) => value.message));

          final notification =
              ref.read(memAfterActStartedNotificationByMemIdProvider(_memId));

          return _AfterActStartedNotificationView(
            time,
            message,
            onTimeChanged: (picked) => ref
                .read(memNotificationsByMemIdProvider(_memId).notifier)
                .upsertAll(
              [
                (notification as MemNotificationEntity)
                    .copiedWith(time: () => picked)
              ],
              (current, updating) => current.type == updating.type,
            ),
            onMessageChanged: (value) => ref
                .read(memNotificationsByMemIdProvider(_memId).notifier)
                .upsertAll(
              [
                (notification as MemNotificationEntity)
                    .copiedWith(message: () => value)
              ],
              (current, updating) => current.type == updating.type,
            ),
          );
        },
        {
          "_memId": _memId,
        },
      );
}

class _AfterActStartedNotificationView extends StatelessWidget {
  final int? _time;
  final String _message;
  final void Function(int? picked) _onTimeChanged;
  final void Function(String value) _onMessageChanged;

  const _AfterActStartedNotificationView(
    this._time,
    this._message, {
    required void Function(int? picked) onTimeChanged,
    required void Function(String value) onMessageChanged,
  })  : _onTimeChanged = onTimeChanged,
        _onMessageChanged = onMessageChanged,
        super(
          key: keyMemAfterActStartedNotification,
        );

  @override
  Widget build(BuildContext context) => v(
        () => Flex(
          direction: Axis.vertical,
          children: [
            ListTile(
              leading: const Icon(Icons.start),
              title: TimeTextFormField(
                _time,
                _onTimeChanged,
              ),
              trailing: _time == null
                  ? null
                  : IconButton(
                      onPressed: () => _onTimeChanged(null),
                      icon: const Icon(Icons.clear),
                    ),
            ),
            ListTile(
              leading: const SizedBox(width: 24.0),
              title: TextFormField(
                initialValue: _message,
                onChanged: _onMessageChanged,
                enabled: _time != null,
              ),
            )
          ],
        ),
        {
          "_time": _time,
          "_message": _message,
        },
      );
}
