import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_actions.dart';
import 'package:mem/component/view/mem_list/states.dart';
import 'package:mem/component/view/timer.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/colors.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/logger/log_service_v2.dart' as v2;
import 'package:mem/mems/mem_list_view_state.dart';
import 'package:mem/mems/mem_period.dart';

import '../../../../mems/mem_done_checkbox.dart';
import 'actions.dart';
import '../../../../mems/mem_name.dart';

class MemListItemView extends ConsumerWidget {
  final MemId _memId;
  final void Function(MemId memId)? _onTapped;

  const MemListItemView(this._memId, this._onTapped, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        {'_memId': _memId},
        () {
          final mem =
              ref.watch(memListProvider).firstWhere((_) => _.id == _memId);

          if (ref.watch(memListViewModeProvider) ==
              MemListViewMode.singleSelection) {
            return _SingleSelectableMemListItemComponent(
              mem,
              ref.watch(selectedMemIdsProvider)?.contains(_memId) ?? false,
              (memId) => v(
                {'memId': memId},
                () => ref
                    .read(selectedMemIdsProvider.notifier)
                    .updatedBy([memId]),
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
              (activeAct) => v2.v(
                () async {
                  if (activeAct == null) {
                    ref.read(startAct(_memId));
                  } else {
                    ref.read(finishAct(activeAct));
                  }
                },
                activeAct,
              ),
              key: key,
            );
          }
        },
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
