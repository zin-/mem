import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';

import 'mem_list_item_action.dart';
import 'start_button.dart';
import 'stop_button.dart';

class TrailingIconButton extends StatelessWidget {
  final Mem _mem;

  const TrailingIconButton._(this._mem);

  static TrailingIconButton? of(WidgetRef ref, Mem mem) {
    final hasNotifications = MemListItemAction.hasEnabledNotifications(
      ref,
      mem.id as int,
    );
    final hasUndoneChildren = MemListItemAction.hasUndoneChildren(
      ref,
      mem.id,
    );
    if (mem.isDone || (!hasNotifications && hasUndoneChildren)) {
      return null;
    }
    return TrailingIconButton._(mem);
  }

  @override
  Widget build(BuildContext context) => v(
        () {
          if (_mem.latestAct is ActiveAct) {
            return StopButton(_mem);
          }
          return StartButton(_mem);
        },
        {'_mem': _mem},
      );
}
