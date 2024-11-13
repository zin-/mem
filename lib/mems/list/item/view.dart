import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/acts/actions.dart';
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
            activeActsProvider.select(
              (v) => v
                  .singleWhereOrNull(
                    (e) => e.value.memId == _memId,
                  )
                  ?.value,
            ),
          ),
          (activeAct) => v(
            () async {
              if (activeAct == null) {
                ref.read(startActBy(_memId));
              } else {
                final finishedActId = ref.read(finishActBy(_memId));
                ref.read(activeActsProvider.notifier).removeWhere(
                      (act) => act.id == finishedActId,
                    );
              }
            },
            {
              'activeAct': activeAct,
            },
          ),
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
  Act? activeAct,
  void Function(Act? act) onActButtonTapped,
  Iterable<MemNotification> memNotifications,
) =>
    v(
      () {
        final hasEnableMemNotifications = memNotifications
            .where((e) => e is SavedMemNotificationEntity && e.isEnabled())
            .isNotEmpty;

        return ListTile(
          title: activeAct == null
              ? MemNameText(mem)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: MemNameText(mem)),
                    ElapsedTimeView(activeAct.period!.start!),
                  ],
                ),
          onTap: () => onTap(mem.id),
          // TODO activeActがあったらPauseボタンを表示する
          // FIXME memNotificationsがあったら表示するべきじゃないのでは？
          leading: !hasEnableMemNotifications && activeAct == null
              ? MemDoneCheckbox(
                  mem,
                  (value) => onMemDoneCheckboxTapped(value, mem.id),
                )
              : null,
          tileColor: mem.isArchived ? secondaryGreyColor : null,
          trailing: !mem.isDone && hasEnableMemNotifications
              ? IconButton(
                  onPressed: () => onActButtonTapped(activeAct),
                  icon: activeAct == null
                      ? const Icon(Icons.play_arrow)
                      : const Icon(Icons.stop),
                )
              : null,
          subtitle: mem.period == null && !hasEnableMemNotifications
              ? null
              : MemListItemSubtitle(mem.id),
          isThreeLine: mem.period != null && hasEnableMemNotifications,
        );
      },
      {
        'mem': mem,
        'activeAct': activeAct,
        'memNotifications': memNotifications,
      },
    );
