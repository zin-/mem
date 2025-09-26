import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/framework/view/timer.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/values/colors.dart';

import 'subtitle.dart';

class MemListItemView extends ConsumerWidget {
  final int _memId;
  final void Function(int memId) _onTapped;

  const MemListItemView(this._memId, this._onTapped, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _render(
          ref.watch(memListProvider).firstWhere((mem) => mem.id == _memId),
          _onTapped,
          (bool? value, int memId) => v(
            () => value == true
                ? ref.read(memEntitiesProvider.notifier).doneMem(_memId)
                : ref.read(memEntitiesProvider.notifier).undoneMem(_memId),
            {
              'value': value,
              'memId': memId,
            },
          ),
          ref.watch(
            latestActsByMemProvider.select(
              (value) => value?[_memId],
            ),
          ),
          () => ref.read(actEntitiesProvider.notifier).startActby(_memId),
          () => ref.read(actEntitiesProvider.notifier).finishActby(_memId),
          () => ref.read(actEntitiesProvider.notifier).pauseByMemId(_memId),
          () => ref.read(actEntitiesProvider.notifier).closeByMemId(_memId),
          ref.watch(memNotificationsByMemIdProvider(_memId)),
        ),
        {
          '_memId': _memId,
        },
      );
}

ListTile _render(
  SavedMemEntity memEntity,
  void Function(int memId) onTap,
  void Function(bool? value, int memId) onMemDoneCheckboxTapped,
  Act? latestActByMem,
  void Function() startAct,
  void Function() finishAct,
  void Function() pauseAct,
  void Function() closeAct,
  Iterable<MemNotificationEntity> memNotificationEntities,
) =>
    v(
      () {
        final hasActiveAct =
            latestActByMem != null && latestActByMem is ActiveAct;
        final hasPausedAct =
            latestActByMem != null && latestActByMem is PausedAct;
        final hasEnableMemNotifications = memNotificationEntities
            .where(
              (e) => e is SavedMemNotificationEntity && e.value.isEnabled(),
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
              ? MemNameTextV2(memEntity.id)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: MemNameTextV2(memEntity.id)),
                    ElapsedTimeView(latestActByMem.period!.start!),
                  ],
                ),
          onTap: () => onTap(memEntity.id),
          leading: hasEnableMemNotifications
              ? hasActiveAct
                  ? pauseIconButton
                  : hasPausedAct
                      ? closeIconButton
                      : stopIconButton
              : MemDoneCheckbox(
                  memEntity,
                  (value) => onMemDoneCheckboxTapped(value, memEntity.id),
                ),
          tileColor: memEntity.isArchived ? secondaryGreyColor : null,
          trailing: !memEntity.value.isDone && hasEnableMemNotifications
              ? hasActiveAct
                  ? stopIconButton
                  : startIconButton
              : null,
          subtitle: memEntity.value.period == null && !hasEnableMemNotifications
              ? null
              : MemListItemSubtitle(memEntity.id),
          isThreeLine:
              memEntity.value.period != null && hasEnableMemNotifications,
        );
      },
      {
        'memEntity': memEntity,
        'latestActByMem': latestActByMem,
        'memNotificationEntities': memNotificationEntities,
      },
    );
