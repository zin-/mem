import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/framework/view/timer.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/mems/mem_done_checkbox.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/values/colors.dart';

import 'actions.dart';
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
            () => ref.read(memsProvider.notifier).upsertAll(
              [
                value == true
                    ? ref.read(doneMem(_memId))
                    : ref.read(undoneMem(_memId))
              ],
              (tmp, item) => tmp is SavedMemEntityV2 && item is SavedMemEntityV2
                  ? tmp.id == item.id
                  : false,
            ),
            {
              'value': value,
              'memId': memId,
            },
          ),
          ref.watch(latestActByMemProvider(_memId)),
          () => ref.read(startActBy(_memId)),
          () => ref.read(finishActBy(_memId)),
          () => ref.read(actsV2Provider.notifier).pause(_memId),
          ref.watch(memNotificationsByMemIdProvider(_memId)),
        ),
        {
          '_memId': _memId,
        },
      );
}

ListTile _render(
  SavedMemEntityV2 memEntity,
  void Function(int memId) onTap,
  void Function(bool? value, int memId) onMemDoneCheckboxTapped,
  Act? latestActByMem,
  void Function() startAct,
  void Function() finishAct,
  void Function() pauseAct,
  Iterable<MemNotificationEntityV2> memNotificationEntities,
) =>
    v(
      () {
        final hasActiveAct =
            latestActByMem != null && latestActByMem is ActiveAct;
        final hasPausedAct =
            latestActByMem != null && latestActByMem is PausedAct;
        final hasEnableMemNotifications = memNotificationEntities
            .where(
              (e) => e is SavedMemNotificationEntityV2 && e.value.isEnabled(),
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

        return ListTile(
          title: !hasActiveAct
              ? MemNameText(memEntity)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: MemNameText(memEntity)),
                    ElapsedTimeView(latestActByMem.period!.start!),
                  ],
                ),
          onTap: () => onTap(memEntity.id),
          leading: hasEnableMemNotifications
              ? hasActiveAct
                  ? pauseIconButton
                  : hasPausedAct
                      ? stopIconButton
                      : null
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
