import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/mem_period.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notifications_text.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/targets/next_at_after_last_act.dart';

class MemListItemSubtitle extends ConsumerWidget {
  final int _memId;

  const MemListItemSubtitle(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.watch(memByMemIdProvider(_memId));
          final target = mem?.target;
          return _MemListItemSubtitle(
            _memId,
            mem?.period,
            ref.watch(
              memNotificationsByMemIdProvider(_memId).select(
                (v) => v.whereType<SavedMemNotificationEntityV1>(),
              ),
            ),
            target == null
                ? null
                : NextAtAfterLastAct.of(
                    target: target,
                    latestAct: mem?.latestAct,
                    scheduleAnchorAct: mem?.scheduleAnchorAct,
                  )?.at,
          );
        },
        {
          '_memId': _memId,
        },
      );
}

class _MemListItemSubtitle extends StatelessWidget {
  final int _memId;
  final DateAndTimePeriod? _memPeriod;
  final Iterable<SavedMemNotificationEntityV1> _savedMemNotificationEntities;
  final DateTime? _nextAt;

  const _MemListItemSubtitle(
    this._memId,
    this._memPeriod,
    this._savedMemNotificationEntities,
    this._nextAt,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final nextAt = _nextAt;
          return Wrap(
            children: [
              if (_memPeriod != null) MemPeriodTexts(_memId),
              if (_savedMemNotificationEntities
                  .where((e) => e.value.isEnabled())
                  .isNotEmpty)
                MemNotificationText(_memId),
              if (nextAt != null)
                renderClockTime(
                  context,
                  TimeOfDay.fromDateTime(nextAt),
                  nextAt,
                ),
            ],
          );
        },
        {
          '_memId': _memId,
          '_memPeriod': _memPeriod,
          '_savedMemNotificationEntities': _savedMemNotificationEntities,
          '_nextAt': _nextAt,
        },
      );
}
