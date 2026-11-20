import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_status.dart';

import 'mem_list_item_action.dart';
import 'start_button.dart';
import 'finish_button.dart';

class TrailingIconButton extends StatelessWidget {
  final Widget _button;

  const TrailingIconButton._(this._button);

  static TrailingIconButton? of(WidgetRef ref, Mem mem) {
    final button = _buttonFor(ref, mem);
    if (button == null) return null;
    return TrailingIconButton._(button);
  }

  static Widget? _buttonFor(WidgetRef ref, Mem mem) {
    final status = mem.status(
      hasEnabledNotifications: MemListItemAction.hasEnabledNotifications(
        ref,
        mem.id as int,
      ),
      hasUndoneChildren: MemListItemAction.hasUndoneChildren(ref, mem.id),
    );
    return switch (status) {
      UndoneParentMemStatus() => null,
      NotifiedMemStatus(:final progress, :final isDone) =>
        _forProgress(mem, progress, isDone),
      DoneableMemStatus(:final progress, :final isDone) =>
        _forProgress(mem, progress, isDone),
    };
  }

  static Widget? _forProgress(Mem mem, ActProgress progress, bool isDone) {
    if (isDone) return null;
    if (progress == ActProgress.active) return FinishButton(mem);
    return StartButton(mem);
  }

  @override
  Widget build(BuildContext context) => v(
        () => _button,
        {'_button': _button},
      );
}
