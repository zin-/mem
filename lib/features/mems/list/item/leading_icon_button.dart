import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_status.dart';
import 'package:mem/features/mems/mems_state.dart';

import 'unpause_button.dart';
import 'mem_list_item_action.dart';
import 'pause_button.dart';
import 'finish_button.dart';

class LeadingIconButton extends ConsumerWidget {
  final Mem _mem;

  const LeadingIconButton(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final status = _status(ref);
          return switch (status) {
            UndoneParentMemStatus() => const Icon(Icons.account_tree),
            NotifiedMemStatus() => _forLatestAct(
                whenOther: FinishButton(_mem),
              ),
            DoneableMemStatus() => _forLatestAct(
                whenOther: MemDoneCheckbox(
                  _mem,
                  (value) => _editDone(ref, _mem.id as int, value),
                ),
              ),
          };
        },
        {'_mem': _mem},
      );

  MemStatus _status(WidgetRef ref) => _mem.status(
        hasEnabledNotifications: MemListItemAction.hasEnabledNotifications(
          ref,
          _mem.id as int,
        ),
        hasUndoneChildren: MemListItemAction.hasUndoneChildren(ref, _mem.id),
      );

  Widget _forLatestAct({required Widget whenOther}) => switch (_mem.latestAct) {
        ActiveAct() => PauseButton(_mem),
        PausedAct() => UnpauseButton(_mem),
        _ => whenOther,
      };

  void _editDone(WidgetRef ref, int memId, bool? value) => v(
        () => value == true
            ? ref.read(memEntitiesProvider.notifier).doneMem(memId)
            : ref.read(memEntitiesProvider.notifier).undoneMem(memId),
        {
          'value': value,
          'memId': memId,
        },
      );
}
