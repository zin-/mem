import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_status_labels.dart';
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/acts/viewed_day.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/list/item/completion_dialog.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_states.dart';
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
            targetsProvider.select(
              (targets) => targets
                  .where((entity) => entity.value.memId == _mem.id)
                  .firstOrNull
                  ?.value,
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
            ref.watch(memNotificationsByMemIdProvider(_mem.id as int)),
            target,
            _amount(ref, _mem.id as int, target),
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
          subtitle: mem.period == null && !hasEnableMemNotifications
              ? null
              : MemListItemSubtitle(mem.id as int),
          isThreeLine: mem.period != null && hasEnableMemNotifications,
        );
      },
      {
        'mem': mem,
        'latestActByMem': latestActByMem,
        'memNotificationEntities': memNotificationEntities,
        'target': target,
        'amount': amount,
      },
    );

DayActAmount? _amount(WidgetRef ref, int memId, Target? target) {
  if (!DayTargetLabel.shows(target)) {
    return null;
  }
  final day = logicalToday(ref.watch(preferenceProvider(startOfDayKey)));
  return ref.watch(viewedDayActAmountProvider(memId, day)).value;
}

Widget _title(
  Mem mem,
  Act? latestAct,
  Target? target,
  DayActAmount? amount,
) {
  final name = MemNameText(mem.id);
  if (!ActStatusLabels.shows(latestAct, target, amount)) {
    return name;
  }
  return Row(
    children: [
      Expanded(child: name),
      ActStatusLabels(latestAct, target, amount),
    ],
  );
}
