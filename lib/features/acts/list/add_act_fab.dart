import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/states.dart';

class ActFab extends ConsumerWidget {
  final int _memId;

  const ActFab(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeActList = (ref.watch(actListProvider(_memId)))
        .where((element) => element.value.period?.end == null);

    if (activeActList.isEmpty) {
      return _StartActFab(
        () => ref.read(actEntitiesProvider.notifier).startActby(_memId),
      );
    } else {
      return _FinishActFab(
        () => ref.read(actEntitiesProvider.notifier).finishActby(
              activeActList.last.value.memId,
            ),
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
