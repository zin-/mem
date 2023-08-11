import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'actions.dart';
import 'states.dart';

class ActFab extends ConsumerWidget {
  final int _memId;

  const ActFab(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeActList = (ref.watch(actListProvider(_memId)) ?? [])
        .where((element) => element.period.end == null);

    if (activeActList.isEmpty) {
      return _StartActFab(
        () async => ref.read(actListProvider(_memId).notifier).upsertAll(
          [ref.read(startActV2(_memId))],
          (tmp, item) => tmp.id == item.id,
        ),
      );
    } else {
      return _FinishActFab(
        () async => ref.read(finishActV2(activeActList.last.memId)),
      );
    }
  }
}

class _StartActFab extends FloatingActionButton {
  const _StartActFab(void Function() onPressed)
      : super(child: const Icon(Icons.play_arrow), onPressed: onPressed);
}

class _FinishActFab extends FloatingActionButton {
  const _FinishActFab(void Function() onPressed)
      : super(child: const Icon(Icons.stop), onPressed: onPressed);
}
