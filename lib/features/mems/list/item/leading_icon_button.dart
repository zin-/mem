import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_status.dart';
import 'package:mem/features/mems/mems_state.dart';

import 'unpause_button.dart';
import 'pause_button.dart';
import 'finish_button.dart';

class LeadingIconButton extends ConsumerWidget {
  final Mem _mem;
  final MemStatus _status;
  final bool _showPause;

  const LeadingIconButton(
    this._mem,
    this._status, {
    bool showPause = true,
    super.key,
  }) : _showPause = showPause;

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => switch (_status) {
          MemStatus.undoneParent => const Icon(Icons.account_tree),
          MemStatus.notified => switch (_mem.latestAct) {
              ActiveAct() when _showPause => PauseButton(_mem),
              PausedAct() when _showPause => UnpauseButton(_mem),
              _ => _notifiedLeading(),
            },
          MemStatus.doneable => switch (_mem.latestAct) {
              ActiveAct() when _showPause => PauseButton(_mem),
              PausedAct() when _showPause => UnpauseButton(_mem),
              _ => MemDoneCheckbox(
                  _mem,
                  (value) => _editDone(ref, _mem.id as int, value),
                ),
            },
        },
        {
          '_mem': _mem,
          '_status': _status,
          '_showPause': _showPause,
        },
      );

  Widget _notifiedLeading() {
    // 一時停止を出さないとき、実行中の終了と一時停止中の開始は trailing だけ
    return switch (_mem.latestAct) {
      ActiveAct() || PausedAct() => const SizedBox.shrink(),
      _ => FinishButton(_mem, enableSkip: true),
    };
  }

  void _editDone(WidgetRef ref, int memId, bool? value) => v(
        () => value == true
            ? ref.read(memEntitiesProvider.notifier).doneMem(memId)
            : ref.read(memEntitiesProvider.notifier).undoneMem(memId),
        {
          'value': value,
          'memId': memId,
        },
      );
}
