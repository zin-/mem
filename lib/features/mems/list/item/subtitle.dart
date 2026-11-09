import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/mem_period.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notifications_text.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';

class MemListItemSubtitle extends ConsumerWidget {
  final int _memId;
  final DateTime? _clockAt;

  const MemListItemSubtitle(this._memId, this._clockAt, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.watch(memByMemIdProvider(_memId));
          return _MemListItemSubtitle(
            _memId,
            mem?.period,
            ref.watch(
              memNotificationsByMemIdProvider(_memId).select(
                (v) => v.whereType<SavedMemNotificationEntityV1>(),
              ),
            ),
            _clockAt,
          );
        },
        {
          '_memId': _memId,
          '_clockAt': _clockAt,
        },
      );
}

class _MemListItemSubtitle extends StatelessWidget {
  final int _memId;
  final DateAndTimePeriod? _memPeriod;
  final Iterable<SavedMemNotificationEntityV1> _savedMemNotificationEntities;
  final DateTime? _clockAt;

  const _MemListItemSubtitle(
    this._memId,
    this._memPeriod,
    this._savedMemNotificationEntities,
    this._clockAt,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final clockAt = _clockAt;
          final enabled =
              _savedMemNotificationEntities.where((e) => e.value.isEnabled());
          final hasRepeatClock = enabled.any((e) => e.value.isRepeated());
          return Wrap(
            children: [
              if (_memPeriod != null) MemPeriodTexts(_memId),
              if (enabled.isNotEmpty)
                MemNotificationText(
                  _memId,
                  clockAt: hasRepeatClock ? clockAt : null,
                ),
              if (clockAt != null && !hasRepeatClock)
                renderClockTime(
                  context,
                  TimeOfDay.fromDateTime(clockAt),
                  clockAt,
                ),
            ],
          );
        },
        {
          '_memId': _memId,
          '_memPeriod': _memPeriod,
          '_savedMemNotificationEntities': _savedMemNotificationEntities,
          '_clockAt': _clockAt,
        },
      );
}
