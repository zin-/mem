import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/framework/view/timer.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/values/colors.dart';

import 'subtitle.dart';

class MemListItemView extends ConsumerWidget {
  final Mem _mem;

  const MemListItemView(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _render(
          _mem,
          () => showMemDetailPage(context, ref, _mem.id as int),
          (bool? value, int memId) => v(
            () => value == true
                ? ref.read(memEntitiesProvider.notifier).doneMem(_mem.id as int)
                : ref
                    .read(memEntitiesProvider.notifier)
                    .undoneMem(_mem.id as int),
            {
              'value': value,
              'memId': memId,
            },
          ),
          ref.watch(
            latestActsByMemProvider.select(
              (value) => value?[_mem.id as int],
            ),
          ),
          () =>
              ref.read(actEntitiesProvider.notifier).startActby(_mem.id as int),
          () => ref
              .read(actEntitiesProvider.notifier)
              .finishActby(_mem.id as int),
          () => ref
              .read(actEntitiesProvider.notifier)
              .pauseByMemId(_mem.id as int),
          () => ref
              .read(actEntitiesProvider.notifier)
              .closeByMemId(_mem.id as int),
          ref.watch(memNotificationsByMemIdProvider(_mem.id as int)),
        ),
        {
          '_mem': _mem,
        },
      );
}

ListTile _render(
  Mem mem,
  void Function() onTap,
  void Function(bool? value, int memId) onMemDoneCheckboxTapped,
  Act? latestActByMem,
  void Function() startAct,
  void Function() finishAct,
  void Function() pauseAct,
  void Function() closeAct,
  Iterable<MemNotificationEntityV1> memNotificationEntities,
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

        final startIconButton = IconButton(
          onPressed: () => startAct(),
          icon: const Icon(Icons.play_arrow),
        );
        final stopIconButton = IconButton(
          onPressed: () => finishAct(),
          icon: const Icon(Icons.stop),
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
          title: !hasActiveAct
              ? MemNameText(mem.id)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: MemNameText(mem.id)),
                    ElapsedTimeView(latestActByMem.period!.start!),
                  ],
                ),
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
      },
    );
