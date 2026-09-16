import 'package:collection/collection.dart';
import 'package:day_picker/day_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/framework/date_and_time/weekday.dart';

const keyMemRepeatByDaysOfWeekNotification =
    Key('mem-repeat-by-days-of-week-notification');

class MemRepeatByDaysOfWeekNotificationView extends ConsumerWidget {
  final int? _memId;

  const MemRepeatByDaysOfWeekNotificationView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final daysOfWeek =
              ref.watch(memNotificationsByMemIdProvider(_memId).select(
            (value) =>
                value.where((element) => element.value.isRepeatByDayOfWeek()),
          ));

          return _MemRepeatByDaysOfWeekNotificationView(
            daysOfWeek
                .map((e) => e.value.time!)
                .sorted((a, b) => a.compareTo(b)),
            (selected) => v(
              () => ref
                  .read(memNotificationsByMemIdProvider(_memId).notifier)
                  .upsertAll(
                    selected.map(
                      (e) =>
                          daysOfWeek.singleWhereOrNull(
                              (element) => element.value.time == e) ??
                          MemNotificationEntityV1(
                            MemNotification.by(
                              _memId,
                              MemNotificationType.repeatByDayOfWeek,
                              e,
                              null,
                            ),
                          ),
                    ),
                    (current, updating) =>
                        current.value.type == updating.value.type &&
                        current.value.time == updating.value.time,
                    removeWhere: (current) =>
                        current.value.type ==
                            MemNotificationType.repeatByDayOfWeek &&
                        current.value.memId == _memId &&
                        !selected.contains(current.value.time),
                  ),
// coverage:ignore-start
              {
// coverage:ignore-end
                'selected': selected,
                'daysOfWeek': daysOfWeek,
              },
            ),
          );
        },
        {
          '_memId': _memId,
        },
      );
}

class _MemRepeatByDaysOfWeekNotificationView extends StatelessWidget {
  final List<int> _repeatByDaysOfWeek;
  final void Function(Iterable<int> selected) _onChanged;

  const _MemRepeatByDaysOfWeekNotificationView(
    this._repeatByDaysOfWeek,
    this._onChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final localizations = MaterialLocalizations.of(context);
          final locale = Localizations.localeOf(context);
          final colorScheme = Theme.of(context).colorScheme;

          return SelectWeekDays(
            onSelect: (days) => _onChanged(days.map(int.parse)),
            days: weekdaysInLocalizedOrder(localizations)
                .map((weekday) => DayInWeek(
                      weekdayLabel(localizations, locale, weekday),
                      dayKey: weekday.toString(),
                      isSelected: _repeatByDaysOfWeek.contains(weekday),
                    ))
                .toList(growable: false),
            backgroundColor: colorScheme.surface,
            selectedDaysFillColor: colorScheme.primary,
            selectedDayTextColor: colorScheme.onPrimary,
            unselectedDaysFillColor: Colors.transparent,
            unSelectedDayTextColor: colorScheme.onSurface,
            elevation: 0,
            border: false,
          );
        },
        {
          '_daysOfWeek': _repeatByDaysOfWeek,
        },
      );
}
