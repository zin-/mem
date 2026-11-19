import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_done_edit.dart';

import 'completion_dialog.dart';

class MemListItemActions {
  final Widget leading;
  final Widget? trailing;

  MemListItemActions._(this.leading, this.trailing);

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
    final hasActiveAct = latestAct != null && latestAct is ActiveAct;
    final hasPausedAct = latestAct != null && latestAct is PausedAct;
    final enableSkipMenu = hasEnableMemNotifications && !hasActiveAct;

    void showCompletionDialog(BuildContext dialogContext) {
      showMemListCompletionDialog(
        dialogContext,
        onFinish: finishAct,
        onSkip: skipAct,
      );
    }

    final stopIconButton = memListCompletionStopButton(
      context: context,
      onFinish: finishAct,
      enableSkipMenu: enableSkipMenu,
      onShowCompletionDialog: showCompletionDialog,
    );
    final startIconButton = IconButton(
      onPressed: () => hasPausedAct ? resumeAct() : startAct(),
      icon: const Icon(Icons.play_arrow),
    );
    final pauseIconButton = IconButton(
      onPressed: pauseAct,
      icon: const Icon(Icons.pause),
    );
    final closeIconButton = IconButton(
      onPressed: closeAct,
      icon: const Icon(Icons.close),
    );
    final doneControl = doneEdit == null
        ? const Icon(Icons.account_tree)
        : MemDoneCheckbox(
            mem,
            doneEdit.onChanged,
          );

    Widget? trailingUnlessDone(Widget button) => mem.isDone ? null : button;

    final Widget leading;
    final Widget? trailing;
    if (hasEnableMemNotifications) {
      leading = hasActiveAct
          ? pauseIconButton
          : hasPausedAct
              ? closeIconButton
              : stopIconButton;
      trailing = trailingUnlessDone(
        hasActiveAct ? stopIconButton : startIconButton,
      );
    } else if (doneEdit == null) {
      leading = doneControl;
      trailing = null;
    } else if (hasActiveAct) {
      leading = pauseIconButton;
      trailing = trailingUnlessDone(stopIconButton);
    } else if (hasPausedAct) {
      leading = closeIconButton;
      trailing = trailingUnlessDone(startIconButton);
    } else {
      leading = doneControl;
      trailing = trailingUnlessDone(startIconButton);
    }

    return MemListItemActions._(leading, trailing);
  }
}
