import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';

import 'completion_dialog.dart';
import 'mem_list_item_action.dart';

class StopButton extends ConsumerWidget {
  final Mem _mem;

  const StopButton(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          void finish() => ref
              .read(actEntitiesProvider.notifier)
              .finishActby(_mem.id as int);
          void skip() =>
              ref.read(actEntitiesProvider.notifier).skipActBy(_mem.id as int);
          return memListCompletionStopButton(
            context: context,
            onFinish: finish,
            enableSkipMenu: _enablesSkip(ref),
            onShowCompletionDialog: (dialogContext) {
              showMemListCompletionDialog(
                dialogContext,
                onFinish: finish,
                onSkip: skip,
              );
            },
          );
        },
        {'_mem': _mem},
      );

  bool _enablesSkip(WidgetRef ref) =>
      MemListItemAction.hasEnabledNotifications(ref, _mem.id as int) &&
      _mem.latestAct is! ActiveAct;
}
