import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_actions.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/components/mem/mem_done_checkbox.dart';
import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/components/mem/mem_period.dart';
import 'package:mem/components/timer.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/values/colors.dart';

import 'actions.dart';
import 'states.dart';

class MemListItemView extends ConsumerWidget {
  final int _memId;
  final void Function(MemId memId)? _onTapped;

  const MemListItemView(this._memId, this._onTapped, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem =
              ref.watch(memListProvider).firstWhere((_) => _.id == _memId);

          if (ref.watch(memListViewModeProvider) ==
              MemListViewMode.singleSelection) {
            return _SingleSelectableMemListItemComponent(
              mem,
              ref.watch(selectedMemIdsProvider)?.contains(_memId) ?? false,
              (memId) => v(
                () => ref
                    .read(selectedMemIdsProvider.notifier)
                    .updatedBy([memId]),
                {'memId': memId},
              ),
              key: key,
            );
          } else {
            return _MemListItemViewComponent(
              mem,
              _onTapped,
              (bool? value, MemId memId) {
                value == true
                    ? ref.read(doneMem(_memId))
                    : ref.read(undoneMem(_memId));
              },
              ref.watch(activeActsProvider)?.singleWhereOrNull(
                    (act) => act.memId == mem.id,
                  ),
              (activeAct) => v(
                () async {
                  if (activeAct == null) {
                    ref
                        .read(activeActsProvider.notifier)
                        .add(ref.read(startActV2(_memId)));
                  } else {
                    ref.read(activeActsProvider.notifier).removeWhere(
                          (act) =>
                              act.id ==
                              ref.read(finishActV2(activeAct.memId)).id,
                        );
                  }
                },
                activeAct,
              ),
              key: key,
            );
          }
        },
        {'_memId': _memId},
      );
}

class _MemListItemViewComponent extends ListTile {
  _MemListItemViewComponent(
    Mem mem,
    void Function(MemId memId)? onTap,
    void Function(bool? value, MemId memId) onMemDoneCheckboxTapped,
    Act? activeAct,
    void Function(Act? act) onActButtonTapped, {
    super.key,
  }) : super(
          leading: activeAct == null
              ? MemDoneCheckbox(
                  mem,
                  (value) => onMemDoneCheckboxTapped(value, mem.id),
                )
              : null,
          trailing: IconButton(
            onPressed: () => onActButtonTapped(activeAct),
            icon: activeAct == null
                ? const Icon(Icons.play_arrow)
                : const Icon(Icons.stop),
          ),
          title: activeAct == null
              ? MemNameText(mem.name, mem.id)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: MemNameText(mem.name, mem.id)),
                    ElapsedTimeView(activeAct.period.start!),
                  ],
                ),
          subtitle: mem.period == null ? null : MemPeriodTexts(mem.id),
          tileColor: mem.isArchived() ? archivedColor : null,
          onTap: onTap == null ? null : () => onTap(mem.id),
        );
}

class _SingleSelectableMemListItemComponent extends ListTile {
  _SingleSelectableMemListItemComponent(
    Mem mem,
    bool isSelected,
    void Function(MemId value) select, {
    super.key,
  }) : super(
          title: MemNameText(mem.name, mem.id),
          subtitle: mem.period == null ? null : MemPeriodTexts(mem.id),
          trailing: Radio<MemId>(
            value: mem.id,
            groupValue: isSelected ? mem.id : null,
            onChanged: (value) => value != null ? select(value) : null,
          ),
          onTap: () {
            select(mem.id);
          },
        );
}
