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

import 'actions.dart';
import 'subtitle.dart';

class MemListItemView extends ConsumerWidget {
  final Mem _mem;
  final Widget? _subtitle;

  const MemListItemView(
    this._mem, {
    Widget? subtitle,
    super.key,
  }) : _subtitle = subtitle;

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
            ref,
            _mem,
            () => showMemDetailPage(context, ref, _mem.id as int),
            _mem.latestAct,
            notifications,
            target,
            amount,
            listAt,
            _subtitle,
          );
        },
        {
          '_mem': _mem,
        },
      );
}

ListTile _render(
  WidgetRef ref,
  Mem mem,
  void Function() onTap,
  Act? latestActByMem,
  Iterable<MemNotificationEntityV1> memNotificationEntities,
  Target? target,
  ActAmount? amount,
  DateTime? listAt,
  Widget? subtitle,
) =>
    v(
      () {
        bool hasEnabledMemNotifications(
          Iterable<MemNotificationEntityV1> notifications,
        ) =>
            notifications
                .where(
                  (e) =>
                      e is SavedMemNotificationEntityV1 && e.value.isEnabled(),
                )
                .isNotEmpty;

        final hasEnableMemNotifications = hasEnabledMemNotifications(
          memNotificationEntities,
        );

        return ListTile(
          title: _title(mem, latestActByMem, target, amount),
          onTap: onTap,
          leading: LeadingIconButton(mem),
          tileColor: mem.isArchived ? secondaryGreyColor : null,
          trailing: TrailingIconButton.of(ref, mem),
          subtitle: subtitle ??
              (mem.period == null &&
                      !hasEnableMemNotifications &&
                      listAt == null
                  ? null
                  : MemListItemSubtitle(mem.id as int, listAt)),
          isThreeLine: subtitle == null &&
              mem.period != null &&
              hasEnableMemNotifications,
        );
      },
      {
        'mem': mem,
        'latestActByMem': latestActByMem,
        'memNotificationEntities': memNotificationEntities,
        'target': target,
        'amount': amount,
        'listAt': listAt,
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
