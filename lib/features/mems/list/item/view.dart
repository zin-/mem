import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_status_labels.dart';
import 'package:mem/features/acts/act_amount.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/acts/target_progress_label.dart';
import 'package:mem/features/mems/count_target.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_status.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/mems/list/list_frame_count.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/values/colors.dart';

import 'leading_icon_button.dart';
import 'subtitle.dart';
import 'trailing_icon_button.dart';

class MemListItemView extends ConsumerWidget {
  final Mem _mem;
  final Widget? _subtitle;
  final bool _showPause;
  final Widget? _beforeLeading;
  final Widget? _afterTrailing;
  final EdgeInsetsGeometry? _contentPadding;

  const MemListItemView(
    this._mem, {
    Widget? subtitle,
    bool showPause = true,
    Widget? beforeLeading,
    Widget? afterTrailing,
    EdgeInsetsGeometry? contentPadding,
    super.key,
  })  : _subtitle = subtitle,
        _showPause = showPause,
        _beforeLeading = beforeLeading,
        _afterTrailing = afterTrailing,
        _contentPadding = contentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final target = ref.watch(
            memEntitiesProvider.select(
              (mems) => mems
                  .where((entity) => entity.id == _mem.id)
                  .firstOrNull
                  ?.target,
            ),
          );
          final notifications =
              ref.watch(memNotificationsByMemIdProvider(_mem.id as int));
          final hasEnabledNotifications = notifications
              .where(
                (e) => e is SavedMemNotificationEntityV1 && e.value.isEnabled(),
              )
              .isNotEmpty;
          final hasUndoneChildren = ref.watch(
            parentMemIdsWithUndoneChildrenProvider.select(
              (ids) => ids.contains(_mem.id),
            ),
          );
          final status = _mem.status(
            hasEnabledNotifications: hasEnabledNotifications,
            hasUndoneChildren: hasUndoneChildren,
          );
          final startOfDay = ref.watch(preferenceProvider(startOfDayKey));
          final periodCount = _periodCount(ref, _mem.id as int);
          final amount = _labelAmount(
            ref,
            _mem,
            target,
            periodCount,
            startOfDay,
          );
          final listAt = _needsPeriodCount(target) && periodCount == null
              ? null
              : _mem
                  .memListAt(
                    DateTimeExt.startOfToday(startOfDay),
                    notifications.map((e) => e.value),
                    target: target,
                    periodCount: periodCount ?? 0,
                  )
                  ?.at;
          return _render(
            _mem,
            () => showMemDetailPage(context, ref, _mem.id as int),
            _mem.latestAct,
            status,
            hasEnabledNotifications,
            target,
            amount,
            listAt,
            _subtitle,
            showPause: _showPause,
            beforeLeading: _beforeLeading,
            afterTrailing: _afterTrailing,
            contentPadding: _contentPadding,
          );
        },
        {
          '_mem': _mem,
          '_showPause': _showPause,
        },
      );
}

ListTile _render(
  Mem mem,
  void Function() onTap,
  Act? latestActByMem,
  MemStatus status,
  bool hasEnabledNotifications,
  Target? target,
  ActAmount? amount,
  DateTime? listAt,
  Widget? subtitle, {
  required bool showPause,
  Widget? beforeLeading,
  Widget? afterTrailing,
  EdgeInsetsGeometry? contentPadding,
}) =>
    v(
      () {
        Widget? place(Widget? first, Widget? second) {
          final children = <Widget>[
            if (first != null) first,
            if (second != null) second,
          ];
          return switch (children.length) {
            0 => null,
            1 => children.single,
            _ => Row(mainAxisSize: MainAxisSize.min, children: children),
          };
        }

        return ListTile(
          contentPadding: contentPadding,
          title: _title(mem, latestActByMem, target, amount),
          onTap: onTap,
          leading: place(
            beforeLeading,
            LeadingIconButton(mem, status, showPause: showPause),
          ),
          tileColor: mem.isArchived ? secondaryGreyColor : null,
          trailing: place(TrailingIconButton.of(mem, status), afterTrailing),
          subtitle: subtitle ??
              (mem.period == null && !hasEnabledNotifications && listAt == null
                  ? null
                  : MemListItemSubtitle(mem.id as int, listAt)),
          isThreeLine:
              subtitle == null && mem.period != null && hasEnabledNotifications,
        );
      },
      {
        'mem': mem,
        'latestActByMem': latestActByMem,
        'status': status,
        'hasEnabledNotifications': hasEnabledNotifications,
        'target': target,
        'amount': amount,
        'listAt': listAt,
        'showPause': showPause,
      },
    );

bool _needsPeriodCount(Target? target) => CountTarget.of(target, 0) != null;

int? _periodCount(WidgetRef ref, int memId) {
  final counts = ref.watch(listPeriodCountByMemIdProvider);
  if (!counts.hasValue) return null;
  return counts.value![memId] ?? 0;
}

ActAmount? _dayAmount(
  WidgetRef ref,
  int memId,
  TimeOfDay startOfDay,
) {
  final day = DateAndTime.now().logicalDay(startOfDay);
  return ref.watch(viewedDayActAmountProvider(memId, day)).value;
}

ActAmount? _labelAmount(
  WidgetRef ref,
  Mem mem,
  Target? target,
  int? periodCount,
  TimeOfDay startOfDay,
) {
  if (!TargetProgressLabel.shows(target)) {
    return null;
  }
  final memId = mem.id as int;
  if (target!.targetUnit == TargetUnit.time) {
    return _dayAmount(ref, memId, startOfDay);
  }
  if (target.targetUnit != TargetUnit.count) {
    return null;
  }
  if (target.period == Period.aDay) {
    if (periodCount == null) return null;
    final shown = ListFrameCount.of(
      target: target,
      periodCount: periodCount,
      latestAct: mem.latestAct,
      scheduleAnchorAct: mem.scheduleAnchorAct,
      startOfToday: DateTimeExt.startOfToday(startOfDay),
      startOfDay: startOfDay,
    );
    return ActAmount(
      shown?.value ?? periodCount,
      Duration.zero,
    );
  }
  final day = _dayAmount(ref, memId, startOfDay);
  if (day == null) return null;
  return ActAmount(day.count, Duration.zero);
}

Widget _title(
  Mem mem,
  Act? latestAct,
  Target? target,
  ActAmount? amount,
) =>
    ActStatusLabels(
      latestAct,
      target,
      amount,
      leading: MemNameText(mem.id),
      shownIn: Period.aDay,
    );
