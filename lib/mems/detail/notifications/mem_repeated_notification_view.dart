import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/settings/states.dart';
import 'package:mem/values/constants.dart';

const keyMemRepeatedNotification = Key("mem-repeated-notification");

class MemRepeatedNotificationView extends ConsumerWidget {
  final int? _memId;

  const MemRepeatedNotificationView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemRepeatedNotificationView(
          ref.watch(memRepeatedNotificationByMemIdProvider(_memId).select(
            (value) => value.time,
          )),
          ref.read(startOfDayProvider) ?? defaultStartOfDay,
          (picked) => ref
              .read(memNotificationsByMemIdProvider(_memId).notifier)
              .upsertAll(
            [
              ref
                  .read(memRepeatedNotificationByMemIdProvider(_memId))
                  .copiedWith(
                    time: () => picked,
                  )
            ],
            (current, updating) => current.type == updating.type,
          ),
        ),
        {
          "_memId": _memId,
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
            timeOfDay: _time == null
                ? _defaultTime
                : () {
                    final hours = (_time / 60 / 60).floor();
                    final minutes = ((_time - hours * 60 * 60) / 60).floor();
                    return TimeOfDay(hour: hours, minute: minutes);
                  }(),
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
          "_time": _time,
        },
      );
}
