import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/i/api.dart';

class SelectMem extends ConsumerWidget {
  const SelectMem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _SelectMemComponent(
      // TODO refer selected
      false,
    );
  }
}

class _SelectMemComponent extends StatelessWidget {
  final bool _selected;

  const _SelectMemComponent(this._selected);

  @override
  Widget build(BuildContext context) => t(
        {'_selected': _selected},
        () {
          return FloatingActionButton(
            onPressed: _selected
                ? () {
                    trace('on pressed');
                  }
                : null,
            child: const Icon(Icons.check),
          );
        },
      );
}
