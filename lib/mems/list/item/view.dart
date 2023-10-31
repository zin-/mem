import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/components/mem/mem_done_checkbox.dart';
import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/components/mem/mem_period.dart';
import 'package:mem/components/timer.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/values/colors.dart';

import 'actions.dart';

class MemListItemView extends ConsumerWidget {
  final int _memId;
  final void Function(int memId) _onTapped;

  const MemListItemView(this._memId, this._onTapped, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemListItemViewComponent(
          ref.watch(memListProvider).firstWhere((_) => _.id == _memId),
          ref.watch(activeActsProvider)?.singleWhereOrNull(
                (act) => act.memId == _memId,
              ),
          ref.watch(memNotificationsByMemIdProvider(_memId))?.singleWhereOrNull(
                (element) =>
                    element.isSaved() &&
                    element.type == MemNotificationType.repeat,
              ),
          _onTapped,
          (bool? value, int memId) async {
            ref.read(memsProvider.notifier).upsertAll(
              [
                value == true
                    ? ref.read(doneMem(_memId))
                    : ref.read(undoneMem(_memId))
              ],
              (tmp, item) => tmp is SavedMem && item is SavedMem
                  ? tmp.id == item.id
                  : false,
            );
          },
          (activeAct) => v(
            () async {
              if (activeAct == null) {
                ref
                    .read(activeActsProvider.notifier)
                    .add(ref.read(startActBy(_memId)).toV1());
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

class _MemListItemViewComponent extends ListTile {
  _MemListItemViewComponent(
    SavedMem mem,
    Act? activeAct,
    MemNotification? memRepeatedNotifications,
    void Function(int memId) onTap,
    void Function(bool? value, int memId) onMemDoneCheckboxTapped,
    void Function(Act? act) onActButtonTapped,
  ) : super(
          leading: memRepeatedNotifications == null
              ? activeAct == null
                  ? MemDoneCheckbox(
                      mem,
                      (value) => onMemDoneCheckboxTapped(value, mem.id),
                    )
                  : null
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
          subtitle: mem.period == null ? null : MemPeriodTexts(mem.id),
          tileColor: mem.isArchived ? archivedColor : null,
          onTap: () => onTap(mem.id),
        ) {
    verbose({
      'mem': mem,
      'activeAct': activeAct,
      'memRepeatedNotifications': memRepeatedNotifications,
    });
  }
}
