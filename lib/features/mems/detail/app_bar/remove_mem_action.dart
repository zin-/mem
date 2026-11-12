import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/app_bar_actions_builder.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/mems/detail/actions.dart';

const keyRemoveMem = Key("remove-mem");

class RemoveMemAction extends AppBarActionBuilder {
  final int _memId;

  RemoveMemAction(this._memId)
      : super(
          key: keyRemoveMem,
          icon: const Icon(Icons.delete),
        );

  @override
  Widget popupMenuItemChildBuilder({
    Key Function()? key,
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      Builder(
        builder: (context) => super.popupMenuItemChildBuilder(
          name: () => buildL10n(context).removeAction,
          onPressed: () => () {
            showDialog(
              context: context,
              builder: (context) => _RemoveMemAlertDialog(_memId),
            );
          },
        ),
      );
}

const keyOk = Key("ok");
const keyCancel = Key("cancel");

class _RemoveMemAlertDialog extends ConsumerWidget {
  final int _memId;

  const _RemoveMemAlertDialog(this._memId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = buildL10n(context);

    return AlertDialog(
      content: Text(l10n.removeConfirmation),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              key: keyOk,
              onPressed: () async {
                if (await ref.read(removeMem(_memId))) {
                  if (context.mounted) {
                    Navigator.of(context)
                      ..pop()
                      ..pop()
                      ..pop(true);
                  }
                }
              },
              child: Text(l10n.okAction),
            ),
            ElevatedButton(
              key: keyCancel,
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
              child: Text(l10n.cancelAction),
            ),
          ],
        ),
      ],
    );
  }
}
