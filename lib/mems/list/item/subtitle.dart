import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/mems/mem_period.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_text.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/mems/mem_notification_entity.dart';

class MemListItemSubtitle extends ConsumerWidget {
  final int _memId;

  const MemListItemSubtitle(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemListItemSubtitle(
          _memId,
          ref.watch(memByMemIdProvider(_memId))?.value.period,
          ref.watch(
            memNotificationsByMemIdProvider(_memId).select(
              (v) => v.whereType<SavedMemNotificationEntityV2>(),
            ),
          ),
        ),
        {
          '_memId': _memId,
        },
      );
}

class _MemListItemSubtitle extends StatelessWidget {
  final int _memId;
  final DateAndTimePeriod? _memPeriod;
  final Iterable<SavedMemNotificationEntityV2> _savedMemNotificationEntities;

  const _MemListItemSubtitle(
    this._memId,
    this._memPeriod,
    this._savedMemNotificationEntities,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          final memNotificationOneLine = MemNotification.toOneLine(
            _savedMemNotificationEntities.map((e) => e.value),
            l10n.repeatedNotificationText,
            l10n.repeatEveryNDayNotificationText,
            l10n.afterActStartedNotificationText,
            (dataAndTime) =>
                TimeOfDay.fromDateTime(dataAndTime).format(context),
          );

          return Wrap(
            children: [
              if (_memPeriod != null) MemPeriodTexts(_memId),
              if (memNotificationOneLine != null) MemNotificationText(_memId),
            ],
          );
        },
        {
          '_memPeriod': _memPeriod,
          '_savedMemNotificationEntities': _savedMemNotificationEntities,
        },
      );
}
