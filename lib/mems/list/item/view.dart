import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/mems/mem_done_checkbox.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/framework/view/timer.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/list/item/subtitle.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/values/colors.dart';

import 'actions.dart';

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
              (tmp, item) => tmp is SavedMemEntity && item is SavedMemEntity
                  ? tmp.id == item.id
                  : false,
            ),
            {
              'value': value,
              'memId': memId,
            },
          ),
          ref.watch(
            latestActsByMemProvider.select(
              (v) => v.singleWhereOrNull(
                (e) => e.memId == _memId,
              ),
            ),
          ),
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
  SavedMemEntity mem,
  void Function(int memId) onTap,
  void Function(bool? value, int memId) onMemDoneCheckboxTapped,
  Act? latestActByMem,
  void Function() startAct,
  void Function() finishAct,
  void Function() pauseAct,
  Iterable<MemNotification> memNotifications,
) =>
    v(
      () {
        final hasActiveAct =
            latestActByMem != null && latestActByMem is ActiveAct;
        final hasPausedAct =
            latestActByMem != null && latestActByMem is PausedAct;
        final hasEnableMemNotifications = memNotifications
            .where((e) => e is SavedMemNotificationEntity && e.isEnabled())
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
              ? MemNameText(mem)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: MemNameText(mem)),
                    ElapsedTimeView(latestActByMem.period!.start!),
                  ],
                ),
          onTap: () => onTap(mem.id),
          leading: hasEnableMemNotifications
              ? hasActiveAct
                  ? pauseIconButton
                  : hasPausedAct
                      ? stopIconButton
                      : null
              : MemDoneCheckbox(
                  mem,
                  (value) => onMemDoneCheckboxTapped(value, mem.id),
                ),
          tileColor: mem.isArchived ? secondaryGreyColor : null,
          trailing: !mem.isDone && hasEnableMemNotifications
              ? hasActiveAct
                  ? stopIconButton
                  : startIconButton
              : null,
          subtitle: mem.period == null && !hasEnableMemNotifications
              ? null
              : MemListItemSubtitle(mem.id),
          isThreeLine: mem.period != null && hasEnableMemNotifications,
        );
      },
      {
        'mem': mem,
        'activeAct': latestActByMem,
        'memNotifications': memNotifications,
      },
    );
