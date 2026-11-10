import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_status_labels.dart';
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/count_target.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/list/item/completion_dialog.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/mems/list/list_frame_count.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/values/colors.dart';

import 'subtitle.dart';

class MemListItemView extends ConsumerWidget {
  final Mem _mem;

  const MemListItemView(this._mem, {super.key});

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
          final hasOpenChildren = ref.watch(
            parentMemIdsWithOpenChildrenProvider.select(
              (ids) => ids.contains(_mem.id),
            ),
          );
          return _render(
            context,
            _mem,
            () => showMemDetailPage(context, ref, _mem.id as int),
            (bool? value, int memId) => v(
              () => value == true
                  ? ref
                      .read(memEntitiesProvider.notifier)
                      .doneMem(_mem.id as int)
                  : ref
                      .read(memEntitiesProvider.notifier)
                      .undoneMem(_mem.id as int),
              {
                'value': value,
                'memId': memId,
              },
            ),
            _mem.latestAct,
            () => ref
                .read(actEntitiesProvider.notifier)
                .startActby(_mem.id as int),
            () => ref
                .read(actEntitiesProvider.notifier)
                .resumeActBy(_mem.id as int),
            () => ref
                .read(actEntitiesProvider.notifier)
                .finishActby(_mem.id as int),
            () => ref
                .read(actEntitiesProvider.notifier)
                .skipActBy(_mem.id as int),
            () => ref
                .read(actEntitiesProvider.notifier)
                .pauseByMemId(_mem.id as int),
            () => ref
                .read(actEntitiesProvider.notifier)
                .closeByMemId(_mem.id as int),
            notifications,
            target,
            amount,
            listAt,
            hasOpenChildren,
          );
        },
        {
          '_mem': _mem,
        },
      );
}

ListTile _render(
  BuildContext context,
  Mem mem,
  void Function() onTap,
  void Function(bool? value, int memId) onMemDoneCheckboxTapped,
  Act? latestActByMem,
  void Function() startAct,
  void Function() resumeAct,
  void Function() finishAct,
  void Function() skipAct,
  void Function() pauseAct,
  void Function() closeAct,
  Iterable<MemNotificationEntityV1> memNotificationEntities,
  Target? target,
  DayActAmount? amount,
  DateTime? listAt,
  bool hasOpenChildren,
) =>
    v(
      () {
        final hasActiveAct =
            latestActByMem != null && latestActByMem is ActiveAct;
        final hasPausedAct =
            latestActByMem != null && latestActByMem is PausedAct;
        final hasEnableMemNotifications = memNotificationEntities
            .where(
              (e) => e is SavedMemNotificationEntityV1 && e.value.isEnabled(),
            )
            .isNotEmpty;
        final enableSkipMenu = hasEnableMemNotifications && !hasActiveAct;
        final showParentIcon = hasOpenChildren && !mem.isDone;

        void showCompletionDialog(BuildContext dialogContext) {
          showMemListCompletionDialog(
            dialogContext,
            onFinish: finishAct,
            onSkip: skipAct,
          );
        }

        final stopIconButton = memListCompletionStopButton(
          context: context,
          onFinish: finishAct,
          enableSkipMenu: enableSkipMenu,
          onShowCompletionDialog: showCompletionDialog,
        );
        final startIconButton = IconButton(
          onPressed: () => hasPausedAct ? resumeAct() : startAct(),
          icon: const Icon(Icons.play_arrow),
        );
        final pauseIconButton = IconButton(
          onPressed: pauseAct,
          icon: const Icon(Icons.pause),
        );
        final closeIconButton = IconButton(
          onPressed: closeAct,
          icon: const Icon(Icons.close),
        );

        return ListTile(
          title: _title(mem, latestActByMem, target, amount),
          onTap: onTap,
          leading: hasEnableMemNotifications
              ? hasActiveAct
                  ? pauseIconButton
                  : hasPausedAct
                      ? closeIconButton
                      : stopIconButton
              : showParentIcon
                  ? const Icon(Icons.account_tree)
                  : MemDoneCheckbox(
                      mem,
                      (value) => onMemDoneCheckboxTapped(value, mem.id as int),
                    ),
          tileColor: mem.isArchived ? secondaryGreyColor : null,
          trailing: !mem.isDone && hasEnableMemNotifications
              ? hasActiveAct
                  ? stopIconButton
                  : startIconButton
              : null,
          subtitle:
              mem.period == null && !hasEnableMemNotifications && listAt == null
                  ? null
                  : MemListItemSubtitle(mem.id as int, listAt),
          isThreeLine: mem.period != null && hasEnableMemNotifications,
        );
      },
      {
        'mem': mem,
        'latestActByMem': latestActByMem,
        'memNotificationEntities': memNotificationEntities,
        'target': target,
        'amount': amount,
        'listAt': listAt,
        'hasOpenChildren': hasOpenChildren,
      },
    );

bool _needsPeriodCount(Target? target) => CountTarget.of(target, 0) != null;

int? _periodCount(WidgetRef ref, int memId) {
  final counts = ref.watch(listPeriodCountByMemIdProvider);
  if (!counts.hasValue) return null;
  return counts.value![memId] ?? 0;
}

DayActAmount? _timeAmount(
  WidgetRef ref,
  int memId,
  Target target,
  TimeOfDay startOfDay,
) {
  final day = DateAndTime.now().logicalDay(startOfDay);
  return ref.watch(viewedDayActAmountProvider(memId, day)).value;
}

DayActAmount? _labelAmount(
  WidgetRef ref,
  Mem mem,
  Target? target,
  int? periodCount,
  TimeOfDay startOfDay,
) {
  if (!DayTargetLabel.shows(target)) {
    return null;
  }
  if (target!.targetUnit == TargetUnit.time) {
    return _timeAmount(ref, mem.id as int, target, startOfDay);
  }
  if (target.targetUnit != TargetUnit.count || periodCount == null) {
    return null;
  }

  final shown = ListFrameCount.of(
    target: target,
    periodCount: periodCount,
    latestAct: mem.latestAct,
    scheduleAnchorAct: mem.scheduleAnchorAct,
    startOfToday: DateTimeExt.startOfToday(startOfDay),
    startOfDay: startOfDay,
  );
  return DayActAmount(
    shown?.value ?? periodCount,
    Duration.zero,
  );
}

Widget _title(
  Mem mem,
  Act? latestAct,
  Target? target,
  DayActAmount? amount,
) =>
    ActStatusLabels(
      latestAct,
      target,
      amount,
      leading: MemNameText(mem.id),
    );
