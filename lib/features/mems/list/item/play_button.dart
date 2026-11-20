import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';

class PlayButton extends ConsumerWidget {
  final Mem _mem;

  const PlayButton(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => IconButton(
          onPressed: () => _play(ref),
          icon: const Icon(Icons.play_arrow),
        ),
        {'_mem': _mem},
      );

  void _play(WidgetRef ref) {
    final memId = _mem.id as int;
    final acts = ref.read(actEntitiesProvider.notifier);
    if (_mem.latestAct is PausedAct) {
      acts.resumeActBy(memId);
      return;
    }
    acts.startActby(memId);
  }
}
