import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_actions.dart';
import 'package:mem/acts/act_list_page_states.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';

class AddActFab extends ConsumerWidget {
  final MemId _memId;

  const AddActFab(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        {'_memId': _memId},
        () {
          return _AddActFabView(
            onPressed: () => v(
              {'_memId': _memId},
              () async {
                ref
                    .read(actListProvider(_memId).notifier)
                    .add(await add(_memId));
              },
            ),
          );
        },
      );
}

class _AddActFabView extends FloatingActionButton {
  const _AddActFabView({required super.onPressed})
      : super(child: const Icon(Icons.add));
}
