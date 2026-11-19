import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_done_edit.dart';
import 'package:mem/features/mems/mems_state.dart';

import 'completion_dialog.dart';

class LeadingIconButton extends ConsumerWidget {
  final Mem _mem;

  const LeadingIconButton(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final memId = _mem.id as int;
          final latestAct = _mem.latestAct;
          final hasNotifications =
              _MemListItemAction._hasEnabledNotifications(ref, memId);
          final hasUndoneChildren =
              _MemListItemAction._hasUndoneChildren(ref, _mem.id);
          if (hasNotifications) {
            if (latestAct is ActiveAct) {
              return PauseButton(_mem);
            }
            if (latestAct is PausedAct) {
              return CloseButton(_mem);
            }
            return StopButton(_mem);
          }
          final doneEdit = MemDoneEdit.of(
            hasUndoneChildren: hasUndoneChildren,
            isDone: _mem.isDone,
            onChanged: (value) => _editDone(ref, memId, value),
          );
          if (doneEdit == null) {
            return const Icon(Icons.account_tree);
          }
          if (latestAct is ActiveAct) {
            return PauseButton(_mem);
          }
          if (latestAct is PausedAct) {
            return CloseButton(_mem);
          }
          return MemDoneCheckbox(_mem, doneEdit.onChanged);
        },
        {'_mem': _mem},
      );

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

class TrailingIconButton extends StatelessWidget {
  final Mem _mem;

  const TrailingIconButton._(this._mem);

  static TrailingIconButton? of(WidgetRef ref, Mem mem) {
    final hasNotifications = _MemListItemAction._hasEnabledNotifications(
      ref,
      mem.id as int,
    );
    final hasUndoneChildren = _MemListItemAction._hasUndoneChildren(
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
          return PlayButton(_mem);
        },
        {'_mem': _mem},
      );
}

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

class CloseButton extends ConsumerWidget {
  final Mem _mem;

  const CloseButton(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => IconButton(
          onPressed: () => ref
              .read(actEntitiesProvider.notifier)
              .closeByMemId(_mem.id as int),
          icon: const Icon(Icons.close),
        ),
        {'_mem': _mem},
      );
}

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

class StopButton extends ConsumerWidget {
  final Mem _mem;

  const StopButton(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          void finish() => ref
              .read(actEntitiesProvider.notifier)
              .finishActby(_mem.id as int);
          void skip() =>
              ref.read(actEntitiesProvider.notifier).skipActBy(_mem.id as int);
          return memListCompletionStopButton(
            context: context,
            onFinish: finish,
            enableSkipMenu: _enablesSkip(ref),
            onShowCompletionDialog: (dialogContext) {
              showMemListCompletionDialog(
                dialogContext,
                onFinish: finish,
                onSkip: skip,
              );
            },
          );
        },
        {'_mem': _mem},
      );

  bool _enablesSkip(WidgetRef ref) =>
      _MemListItemAction._hasEnabledNotifications(ref, _mem.id as int) &&
      _mem.latestAct is! ActiveAct;
}

mixin _MemListItemAction {
  static bool _hasEnabledNotifications(WidgetRef ref, int memId) => ref
      .watch(memNotificationsByMemIdProvider(memId))
      .where(
        (e) => e is SavedMemNotificationEntityV1 && e.value.isEnabled(),
      )
      .isNotEmpty;

  static bool _hasUndoneChildren(WidgetRef ref, MemId memId) => ref.watch(
        parentMemIdsWithUndoneChildrenProvider.select(
          (ids) => ids.contains(memId),
        ),
      );
}
