import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_status.dart';

import 'start_button.dart';
import 'finish_button.dart';

class TrailingIconButton extends StatelessWidget {
  final Widget _button;

  const TrailingIconButton._(this._button);

  static TrailingIconButton? of(Mem mem, MemStatus status) {
    final button = _buttonFor(mem, status);
    if (button == null) return null;
    return TrailingIconButton._(button);
  }

  static Widget? _buttonFor(Mem mem, MemStatus status) {
    Widget forLatestAct() => switch (mem.latestAct) {
          ActiveAct() => FinishButton(mem, enableSkip: false),
          _ => StartButton(mem),
        };

    if (status == MemStatus.undoneParent || mem.isDone) return null;
    return forLatestAct();
  }

  @override
  Widget build(BuildContext context) => v(
        () => _button,
        {'_button': _button},
      );
}
