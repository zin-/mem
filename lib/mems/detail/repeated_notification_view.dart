import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/core/mem_repeated_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/core/date_and_time/time_of_day.dart' as core;

// TODO 開始後、指定された時間後に通知する
//  時間（何分後みたいな）とメッセージ（止めようみたいな）を保存する
//  TODO mem_repeated_notificationsをmem_notificationsに変更して、type
//  とmessageを持たせる
class NotificationWidget extends ConsumerWidget {
  final int? _memId;

  const NotificationWidget(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadMemNotification(_memId),
          (loaded) {
            final repeatedNotification =
                ref.watch(memNotificationProvider(_memId));

            return _RepeatedNotificationWidgetComponent(
              repeatedNotification?.timeOfDay.convert(),
              (pickedTimeOfDay) {
                ref.read(memNotificationProvider(_memId).notifier).updatedBy(
                      pickedTimeOfDay == null
                          ? null
                          : MemNotification(
                              pickedTimeOfDay.convert(),
                              memId: _memId,
                              id: repeatedNotification?.id,
                              createdAt: repeatedNotification?.createdAt,
                              updatedAt: repeatedNotification?.updatedAt,
                              archivedAt: repeatedNotification?.archivedAt,
                            ),
                    );
              },
            );
          },
        ),
        _memId,
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

extension on core.TimeOfDay {
  TimeOfDay convert() => TimeOfDay(hour: hour, minute: minute);
}

extension on TimeOfDay {
  core.TimeOfDay convert() => core.TimeOfDay(hour, minute);
}
