import 'package:material_ui/material_ui.dart' hide CloseButton;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_done_edit.dart';
import 'package:mem/features/mems/mems_state.dart';

import 'close_button.dart';
import 'mem_list_item_action.dart';
import 'pause_button.dart';
import 'stop_button.dart';

class LeadingIconButton extends ConsumerWidget {
  final Mem _mem;

  const LeadingIconButton(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final memId = _mem.id as int;
          final latestAct = _mem.latestAct;
          final hasNotifications =
              MemListItemAction.hasEnabledNotifications(ref, memId);
          final hasUndoneChildren =
              MemListItemAction.hasUndoneChildren(ref, _mem.id);
          if (hasNotifications) {
            if (latestAct is ActiveAct) {
              return PauseButton(_mem);
            }
            if (latestAct is PausedAct) {
              return CloseButton(_mem);
            }
            return StopButton(_mem);
          }
          final doneEdit = MemDoneEdit.of(
            hasUndoneChildren: hasUndoneChildren,
            isDone: _mem.isDone,
            onChanged: (value) => _editDone(ref, memId, value),
          );
          if (doneEdit == null) {
            return const Icon(Icons.account_tree);
          }
          if (latestAct is ActiveAct) {
            return PauseButton(_mem);
          }
          if (latestAct is PausedAct) {
            return CloseButton(_mem);
          }
          return MemDoneCheckbox(_mem, doneEdit.onChanged);
        },
        {'_mem': _mem},
      );

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
