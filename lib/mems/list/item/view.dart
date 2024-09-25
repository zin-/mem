import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:mem/acts/act_entity.dart';
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
        () => _MemListItemView(
          ref.watch(memListProvider).firstWhere((mem) => mem.id == _memId),
          ref.watch(activeActsProvider).singleWhereOrNull(
                (act) => act.memId == _memId,
              ),
          ref.watch(memNotificationsByMemIdProvider(_memId)),
          _onTapped,
          (bool? value, int memId) async {
            ref.read(memsProvider.notifier).upsertAll(
              [
                value == true
                    ? ref.read(doneMem(_memId))
                    : ref.read(undoneMem(_memId))
              ],
              (tmp, item) => tmp is SavedMemEntity && item is SavedMemEntity
                  ? tmp.id == item.id
                  : false,
            );
          },
          (activeAct) => v(
            () async {
              if (activeAct == null) {
                ref.read(startActBy(_memId));
              } else {
                ref.read(activeActsProvider.notifier).removeWhere(
                      (act) =>
                          act.id == ref.read(finishActBy(activeAct.memId)).id,
                    );
              }
            },
            activeAct,
          ),
        ),
        _memId,
      );
}

class _MemListItemView extends ListTile {
  _MemListItemView(
    SavedMemEntity mem,
    SavedActEntity? activeAct,
    Iterable<MemNotification> memNotifications,
    void Function(int memId) onTap,
    void Function(bool? value, int memId) onMemDoneCheckboxTapped,
    void Function(SavedActEntity? act) onActButtonTapped,
  ) : super(
          leading: memNotifications
                      .where((e) =>
                          e is SavedMemNotificationEntity && e.isEnabled())
                      .isEmpty &&
                  activeAct == null
              ? MemDoneCheckbox(
                  mem,
                  (value) => onMemDoneCheckboxTapped(value, mem.id),
                )
              : null,
          trailing: mem.isDone
              ? null
              : IconButton(
                  onPressed: () => onActButtonTapped(activeAct),
                  icon: activeAct == null
                      ? const Icon(Icons.play_arrow)
                      : const Icon(Icons.stop),
                ),
          title: activeAct == null
              ? MemNameText(mem)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: MemNameText(mem)),
                    ElapsedTimeView(activeAct.period.start!),
                  ],
                ),
          subtitle: mem.period == null &&
                  memNotifications
                      .where((e) =>
                          e is SavedMemNotificationEntity && e.isEnabled())
                      .isEmpty
              ? null
              : MemListItemSubtitle(mem.id),
          isThreeLine: mem.period != null &&
              memNotifications
                  .where(
                      (e) => e is SavedMemNotificationEntity && e.isEnabled())
                  .isNotEmpty,
          tileColor: mem.isArchived ? secondaryGreyColor : null,
          onTap: () => onTap(mem.id),
        ) {
    verbose({
      'mem': mem,
      'activeAct': activeAct,
      'memNotifications': memNotifications,
    });
  }
}
