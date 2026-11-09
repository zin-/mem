import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/framework/date_and_time/weekday.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/values/colors.dart';

class MemNotificationText extends ConsumerWidget {
  final int? _memId;
  final DateTime? _clockAt;

  const MemNotificationText(
    this._memId, {
    DateTime? clockAt,
    super.key,
  }) : _clockAt = clockAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemNotificationText(
          ref.watch(memNotificationsByMemIdProvider(_memId)),
          ref.watch(preferenceProvider(startOfDayKey)),
          ref.watch(
            memEntitiesProvider.select(
              (mems) => mems
                  .singleWhereOrNull((e) => e.id == _memId)
                  ?.resolvedScheduleAnchor,
            ),
          ),
          _clockAt,
        ),
        {
          '_memId': _memId,
          '_clockAt': _clockAt,
        },
      );
}

class _MemNotificationText extends StatelessWidget {
  final Iterable<MemNotificationEntityV1> _memNotificationEntities;
  final TimeOfDay _startOfDay;
  final Act? _scheduleAnchor;
  final DateTime? _clockAt;

  const _MemNotificationText(
    this._memNotificationEntities,
    this._startOfDay,
    this._scheduleAnchor,
    this._clockAt,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          final localizations = MaterialLocalizations.of(context);
          final locale = Localizations.localeOf(context);

          final enables =
              _memNotificationEntities.where((e) => e.value.isEnabled());

          final oneLine = MemNotification.toOneLine(
            enables.map((e) => e.value),
            (weekday) => weekdayLabel(localizations, locale, weekday),
            weekdaysInLocalizedOrder(localizations),
            l10n.afterActStartedNotificationText,
            (time) => time.format(context),
          );
          final nextNotifyAt = MemNotification.nextNotifyAt(
            enables.map((e) => e.value),
            DateTimeExt.startOfToday(_startOfDay),
            _scheduleAnchor,
          );
          final repeatMemNotification = enables
              .map((e) => e.value)
              .whereType<RepeatMemNotification>()
              .singleOrNull;
          final nDayMemNotification = enables
              .map((e) => e.value)
              .whereType<RepeatByNDayMemNotification>()
              .singleOrNull;
          final clockAt = _clockAt;
          final shownAt = clockAt ?? nextNotifyAt;

          return enables.isEmpty
              ? Text(
                  l10n.noNotifications,
                  style: TextStyle(
                    color: secondaryGreyColor,
                  ),
                )
              : Wrap(
                  spacing: 4.0,
                  children: [
                    if (repeatMemNotification != null && shownAt != null)
                      renderRepeatMemNotification(
                        context,
                        repeatMemNotification,
                        shownAt,
                        time: clockAt == null
                            ? null
                            : TimeOfDay.fromDateTime(clockAt),
                      ),
                    if (nDayMemNotification != null)
                      renderRepeatByNDayMemNotification(
                        context,
                        nDayMemNotification,
                      ),
                    if (oneLine != null)
                      Text(
                        oneLine,
                        style: TextStyle(
                          color: null,
                        ),
                      )
                  ],
                );
        },
        {
          '_memNotificationEntities': _memNotificationEntities,
          '_startOfDay': _startOfDay,
          '_clockAt': _clockAt,
        },
      );
}

Widget renderRepeatMemNotification(
  BuildContext context,
  RepeatMemNotification repeat,
  DateTime at, {
  TimeOfDay? time,
}) =>
    v(
      () => renderClockTime(context, time ?? repeat.timeOfDay!, at),
      {
        'context': context,
        'repeatMemNotification': repeat,
        'at': at,
        'time': time,
      },
    );

Widget renderClockTime(
  BuildContext context,
  TimeOfDay time,
  DateTime at,
) =>
    Text(
      time.format(context),
      style: TextStyle(
        color: DateTime.now().isAfter(at) ? warningColor : null,
      ),
    );

Widget renderRepeatByNDayMemNotification(
  BuildContext context,
  RepeatByNDayMemNotification repeatByNDay,
) =>
    v(
      () {
        final l10n = buildL10n(context);

        if (repeatByNDay.time == 1) {
          return Text(l10n.repeatEverydayNotificationText);
        } else {
          return Text(
            l10n.repeatEveryNDayNotificationText(repeatByNDay.time.toString()),
          );
        }
      },
      {
        'context': context,
        'repeatMemNotification': repeatByNDay,
      },
    );
