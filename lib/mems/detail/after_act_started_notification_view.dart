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
          final notification =
              ref.watch(memAfterActStartedNotificationByMemIdProvider(_memId));

          return Flex(
            direction: Axis.vertical,
            children: [
              ListTile(
                leading: const Icon(Icons.start),
                title: TimeTextFormField(
                  notification.time,
                  (pickedSecondsOfTime) {
                    ref
                        .read(memAfterActStartedNotificationByMemIdProvider(
                                _memId)
                            .notifier)
                        .updatedBy(notification.copiedWith(
                            time: () => pickedSecondsOfTime));
                  },
                ),
              ),
              // TODO disable on no time
              ListTile(
                leading: const SizedBox(width: 24.0),
                title: TextFormField(
                  initialValue: notification.message,
                  onChanged: (value) {
                    ref
                        .read(memAfterActStartedNotificationByMemIdProvider(
                                _memId)
                            .notifier)
                        .updatedBy(
                            notification.copiedWith(message: () => value));
                  },
                ),
              ),
            ],
          );
        },
        {"_memId": _memId},
      );
}
