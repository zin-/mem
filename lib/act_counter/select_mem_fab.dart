import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/act_counter/act_counter_configure_actions.dart';
import 'package:mem/gui/colors.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_list_view_state.dart';

class SelectMemFab extends ConsumerWidget {
  const SelectMemFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMemIds = ref.watch(selectedMemIdsProvider);
    return _SelectMemComponent(
      selectedMemIds?.isNotEmpty ?? false,
      () {
        final selectedMemId = selectedMemIds?.single;
        if (selectedMemId != null) {
          ref.read(selectMem(selectedMemId));
        } else {
          throw Error();
        }
      },
    );
  }
}

class _SelectMemComponent extends StatelessWidget {
  final bool _selected;
  final void Function() _onPressed;

  const _SelectMemComponent(this._selected, this._onPressed);

  @override
  Widget build(BuildContext context) => t(
        {'_selected': _selected},
        () => FloatingActionButton(
          backgroundColor: _selected ? null : archivedColor,
          onPressed: _selected ? _onPressed : null,
          child: const Icon(
            Icons.check,
          ),
        ),
      );
}
