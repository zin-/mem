import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';

import 'act_actions.dart';
import 'act_list_states.dart';

class ActFab extends ConsumerWidget {
  final MemId _memId;

  const ActFab(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actList = ref.watch(actListProvider(_memId));

    if (actList!.isEmpty || actList.first.period.end != null) {
      return _StartActFab(
        () => v(
          () async {
            ref.read(startAct(_memId));
          },
        ),
      );
    } else {
      return _FinishActFab(
        () => v(
          () async {
            ref.read(finishAct(actList.first));
          },
        ),
      );
    }
  }
}

class _StartActFab extends FloatingActionButton {
  const _StartActFab(onPressed)
      : super(child: const Icon(Icons.play_arrow), onPressed: onPressed);
}

class _FinishActFab extends FloatingActionButton {
  const _FinishActFab(onPressed)
      : super(child: const Icon(Icons.stop), onPressed: onPressed);
}
