import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';

import 'completion_dialog.dart';

class FinishButton extends ConsumerWidget {
  final Mem _mem;
  final bool _enableSkip;

  const FinishButton(
    this._mem, {
    required bool enableSkip,
    super.key,
  }) : _enableSkip = enableSkip;

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
            enableSkipMenu: _enableSkip,
            onShowCompletionDialog: (dialogContext) {
              showMemListCompletionDialog(
                dialogContext,
                onFinish: finish,
                onSkip: skip,
              );
            },
          );
        },
        {
          '_mem': _mem,
          '_enableSkip': _enableSkip,
        },
      );
}
