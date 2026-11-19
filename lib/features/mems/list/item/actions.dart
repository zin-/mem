import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_done_edit.dart';

import 'completion_dialog.dart';

class MemListItemActions {
  final Widget leading;
  final Widget? trailing;

  MemListItemActions._({
    required this.leading,
    this.trailing,
  });

  static MemListItemActions of({
    required BuildContext context,
    required Mem mem,
    required Act? latestAct,
    required bool hasEnableMemNotifications,
    required MemDoneEdit? doneEdit,
    required void Function() startAct,
    required void Function() resumeAct,
    required void Function() finishAct,
    required void Function() skipAct,
    required void Function() pauseAct,
    required void Function() closeAct,
  }) {
    final controls = _MemListItemControls(
      context: context,
      mem: mem,
      latestAct: latestAct,
      startAct: startAct,
      resumeAct: resumeAct,
      finishAct: finishAct,
      skipAct: skipAct,
      pauseAct: pauseAct,
      closeAct: closeAct,
    );
    if (hasEnableMemNotifications) {
      return controls.alongAct(enableSkip: true);
    }
    if (doneEdit == null) {
      return MemListItemActions._(leading: const Icon(Icons.account_tree));
    }
    if (controls.isRunning) {
      return controls.alongAct(enableSkip: false);
    }
    return controls.idle(doneEdit);
  }
}

class _MemListItemControls {
  final BuildContext context;
  final Mem mem;
  final Act? latestAct;
  final void Function() startAct;
  final void Function() resumeAct;
  final void Function() finishAct;
  final void Function() skipAct;
  final void Function() pauseAct;
  final void Function() closeAct;

  _MemListItemControls({
    required this.context,
    required this.mem,
    required this.latestAct,
    required this.startAct,
    required this.resumeAct,
    required this.finishAct,
    required this.skipAct,
    required this.pauseAct,
    required this.closeAct,
  });

  bool get isRunning => latestAct is ActiveAct || latestAct is PausedAct;

  MemListItemActions alongAct({required bool enableSkip}) {
    if (latestAct is ActiveAct) {
      return _open(
        _iconButton(Icons.pause, pauseAct),
        _stop(enableSkip: false),
      );
    }
    if (latestAct is PausedAct) {
      return _open(
        _iconButton(Icons.close, closeAct),
        _iconButton(Icons.play_arrow, resumeAct),
      );
    }
    return _open(
      _stop(enableSkip: enableSkip),
      _iconButton(Icons.play_arrow, startAct),
    );
  }

  MemListItemActions idle(MemDoneEdit doneEdit) => _open(
        MemDoneCheckbox(mem, doneEdit.onChanged),
        _iconButton(Icons.play_arrow, startAct),
      );

  MemListItemActions _open(Widget leading, Widget trailing) =>
      MemListItemActions._(
        leading: leading,
        trailing: mem.isDone ? null : trailing,
      );

  Widget _iconButton(IconData icon, void Function() onPressed) => IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
      );

  Widget _stop({required bool enableSkip}) => memListCompletionStopButton(
        context: context,
        onFinish: finishAct,
        enableSkipMenu: enableSkip,
        onShowCompletionDialog: (dialogContext) {
          showMemListCompletionDialog(
            dialogContext,
            onFinish: finishAct,
            onSkip: skipAct,
          );
        },
      );
}
