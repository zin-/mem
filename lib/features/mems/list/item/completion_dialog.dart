import 'package:flutter/material.dart';
import 'package:mem/l10n/l10n.dart';

Future<void> showMemListCompletionDialog(
  BuildContext context, {
  required VoidCallback onFinish,
  required VoidCallback onSkip,
}) async {
  final l10n = buildL10n(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(l10n.memListCompletionDialogTitle),
      children: [
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(dialogContext);
            onFinish();
          },
          child: Text(l10n.memListCompletionDialogFinish),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(dialogContext);
            onSkip();
          },
          child: Text(l10n.memListCompletionDialogSkip),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancelAction),
        ),
      ],
    ),
  );
}

Widget memListCompletionStopButton({
  required VoidCallback onFinish,
  required bool enableSkipMenu,
  required void Function(BuildContext context) onShowCompletionDialog,
  required BuildContext context,
}) {
  final button = IconButton(
    onPressed: onFinish,
    icon: const Icon(Icons.stop),
  );
  if (!enableSkipMenu) {
    return button;
  }
  return GestureDetector(
    onLongPress: () => onShowCompletionDialog(context),
    child: button,
  );
}
