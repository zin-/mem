import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/time_text_form_field.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';

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
                .read(memAfterActStartedNotificationByMemIdProvider(_memId)
                    .notifier)
                .updatedBy(notification.copiedWith(time: () => picked)),
            onMessageChanged: (value) => ref
                .read(memAfterActStartedNotificationByMemIdProvider(_memId)
                    .notifier)
                .updatedBy(notification.copiedWith(message: () => value)),
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
        _onMessageChanged = onMessageChanged;

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
            // TODO disable on no time
            ListTile(
              leading: const SizedBox(width: 24.0),
              title: TextFormField(
                initialValue: _message,
                onChanged: _onMessageChanged,
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
