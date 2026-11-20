import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';

class PauseButton extends ConsumerWidget {
  final Mem _mem;

  const PauseButton(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => IconButton(
          onPressed: () => ref
              .read(actEntitiesProvider.notifier)
              .pauseByMemId(_mem.id as int),
          icon: const Icon(Icons.pause),
        ),
        {'_mem': _mem},
      );
}
