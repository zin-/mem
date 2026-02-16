import 'package:collection/collection.dart';
import 'package:day_picker/day_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';

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
  final List<int> _daysOfWeek = [1, 2, 3, 4, 5, 6, 7];

  final List<int> _repeatByDaysOfWeek;
  final void Function(Iterable<int> selected) _onChanged;

  _MemRepeatByDaysOfWeekNotificationView(
    this._repeatByDaysOfWeek,
    this._onChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          // FIXME ここなんとかならんかな
          final dateFormat = DateFormat.E();
          final now = DateTime.now();
          final theme = Theme.of(context);

          return Padding(
            padding: const EdgeInsets.all(0.0),
            child: SelectWeekDays(
              onSelect: (List<String> e) =>
                  _onChanged(e.map((e) => int.parse(e))),
              days: _daysOfWeek
                  .map((e) => now.add(Duration(days: e)))
                  .sorted((a, b) => a.weekday.compareTo(b.weekday))
                  .mapIndexed((index, e) => DayInWeek(dateFormat.format(e),
                      dayKey: (index + 1).toString(),
                      isSelected: _repeatByDaysOfWeek.contains(index + 1)))
                  .toList(growable: false),
              backgroundColor: theme.canvasColor,
              selectedDaysFillColor: theme.primaryColor,
              selectedDayTextColor: theme.tabBarTheme.indicatorColor,
              unSelectedDayTextColor: theme.unselectedWidgetColor,
              border: false,
            ),
          );
        },
        {
          '_daysOfWeek': _repeatByDaysOfWeek,
        },
      );
}
