import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/list/page.dart';
import 'package:mem/acts/line_chart/line_chart_page.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/values/durations.dart';

enum MenuOption { remove }

class MemDetailMenu extends ConsumerWidget {
  final int? _memId;

  const MemDetailMenu(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mem = ref.watch(memDetailProvider(_memId)).mem;

    return _MemDetailMenuComponent(
      mem,
      () => ref.read(unarchiveMem(_memId!)),
      () => ref.read(archiveMem(_memId!)),
      () => ref.read(removeMem(_memId!)),
    );
  }
}

class _MemDetailMenuComponent extends StatelessWidget {
  final MemV2 _mem;
  final Future<MemDetail?> Function() _unarchiveMem;
  final Future<MemDetail?> Function() _archiveMem;
  final Future<bool> Function() _removeMem;

  const _MemDetailMenuComponent(
    this._mem,
    this._unarchiveMem,
    this._archiveMem,
    this._removeMem,
  );

  @override
  Widget build(BuildContext context) {
    final menu = <Widget>[];

    if (_mem is SavedMemV2) {
      menu.add(_showActChartIconButton(
          Navigator.of(context), (_mem as SavedMemV2).id));
      menu.add(_showActIconButton(context, (_mem as SavedMemV2).id));

      if ((_mem as SavedMemV2).isArchived) {
        menu.add(_unarchiveIconButton(context));
      } else {
        menu.add(_archiveIconButton(context));
      }

      menu.add(_menu(context));
    }

    return Row(
      children: menu,
    );
  }

  IconButton _showActChartIconButton(
    NavigatorState navigatorState,
    int memId,
  ) =>
      IconButton(
        onPressed: () {
          navigatorState.push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ActLineChartPage(memId),
            ),
          );
        },
        icon: const Icon(
          Icons.show_chart,
          color: Colors.white,
        ),
      );

  IconButton _showActIconButton(BuildContext context, int memId) => IconButton(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ActListPage(memId),
            ),
          );
        },
        icon: const Icon(
          Icons.play_arrow,
          color: Colors.white,
        ),
      );

  IconButton _unarchiveIconButton(BuildContext context) => IconButton(
        icon: const Icon(Icons.unarchive),
        color: Colors.white,
        onPressed: () {
          final l10n = buildL10n(context);

          _unarchiveMem();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.unarchiveMemSuccessMessage(
                _mem.name,
              )),
              duration: defaultDismissDuration,
              dismissDirection: DismissDirection.horizontal,
            ),
          );
        },
      );

  IconButton _archiveIconButton(BuildContext context) => IconButton(
        icon: const Icon(Icons.archive),
        color: Colors.white,
        onPressed: () {
          final l10n = buildL10n(context);

          _archiveMem();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.archiveMemSuccessMessage(
                _mem.name,
              )),
              duration: defaultDismissDuration,
              dismissDirection: DismissDirection.horizontal,
            ),
          );

          Navigator.of(context).pop(null);
        },
      );

  Widget _menu(BuildContext context) {
    final l10n = buildL10n(context);

    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: MenuOption.remove,
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.black),
              Text(l10n.removeAction)
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == MenuOption.remove) {
          showDialog(
            context: context,
            builder: (context) => _RemoveMemAlertDialog(_removeMem),
          );
        }
      },
    );
  }
}

class _RemoveMemAlertDialog extends StatelessWidget {
  final Future<bool> Function() _removeMem;

  const _RemoveMemAlertDialog(this._removeMem);

  @override
  Widget build(BuildContext context) {
    final l10n = buildL10n(context);

    return AlertDialog(
      content: Text(l10n.removeConfirmation),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () async {
                if (await _removeMem()) {
                  if (context.mounted) {
                    Navigator.of(context)
                      ..pop()
                      ..pop(true);
                  }
                }
              },
              child: Text(l10n.okAction),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelAction),
            ),
          ],
        ),
      ],
    );
  }
}
