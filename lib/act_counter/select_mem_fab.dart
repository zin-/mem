import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/values/colors.dart';

import 'actions.dart';
import 'states.dart';

class SelectMemFab extends ConsumerWidget {
  const SelectMemFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMemIds = ref.watch(selectedMemIdsProvider);
    return _SelectMemComponent(
      selectedMemIds?.isNotEmpty ?? false,
      () => ref.read(selectMem((selectedMemIds?.single)!)),
    );
  }
}

class _SelectMemComponent extends StatelessWidget {
  final bool _selected;
  final void Function() _onPressed;

  const _SelectMemComponent(this._selected, this._onPressed);

  @override
  Widget build(BuildContext context) => i(
        () => FloatingActionButton(
          backgroundColor: _selected ? null : archivedColor,
          onPressed: _selected ? _onPressed : null,
          child: const Icon(
            Icons.check,
          ),
        ),
        {'_selected': _selected},
      );
}
