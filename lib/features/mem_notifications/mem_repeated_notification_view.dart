import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/time_of_day.dart';
import 'package:mem/framework/date_and_time/time_of_day_view.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';

const keyMemRepeatedNotification = Key('mem-repeated-notification');

class MemRepeatedNotificationView extends ConsumerWidget {
  final int? _memId;

  const MemRepeatedNotificationView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final memRepeatNotification = ref.watch(
            memNotificationsByMemIdProvider(_memId).select(
              (v) => v.singleWhere(
                (e) => e.value.isRepeated(),
              ),
            ),
          );

          return _MemRepeatedNotificationView(
            memRepeatNotification.value.time,
            ref.watch(preferenceProvider(startOfDayKey)),
            (picked) => ref
                .read(memNotificationsByMemIdProvider(_memId).notifier)
                .upsertAll(
              [
                memRepeatNotification.updatedWith(
                  (v) => MemNotification.by(
                    v.memId,
                    v.type,
                    picked,
                    v.message,
                  ),
                ),
              ],
              (current, updating) => current.value.type == updating.value.type,
            ),
          );
        },
        {
          '_memId': _memId,
        },
      );
}

class _MemRepeatedNotificationView extends StatelessWidget {
  final int? _time;
  final TimeOfDay _defaultTime;
  final void Function(int? picked) _onTimeChanged;

  const _MemRepeatedNotificationView(
    this._time,
    this._defaultTime,
    this._onTimeChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () => ListTile(
          key: keyMemRepeatedNotification,
          title: TimeOfDayTextFormField(
            timeOfDay:
                _time == null ? _defaultTime : TimeOfDayExt.fromSeconds(_time),
            onChanged: (pickedTimeOfDay) => _onTimeChanged(
              pickedTimeOfDay == null
                  ? null
                  : ((pickedTimeOfDay.hour * 60 + pickedTimeOfDay.minute) * 60),
            ),
          ),
          trailing: _time == null
              ? null
              : IconButton(
                  onPressed: () => _onTimeChanged(null),
                  icon: const Icon(Icons.clear),
                ),
        ),
        {
          '_time': _time,
        },
      );
}
