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
          final hasNotifications = _hasEnabledNotifications(ref, memId);
          final hasUndoneChildren = _hasUndoneChildren(ref, _mem.id);
          if (hasNotifications) {
            return _alongAct(
              context,
              ref,
              memId,
              latestAct,
              enableSkip: true,
            );
          }
          final doneEdit = MemDoneEdit.of(
            hasUndoneChildren: hasUndoneChildren,
            isDone: _mem.isDone,
            onChanged: (value) => _editDone(ref, memId, value),
          );
          if (doneEdit == null) {
            return const Icon(Icons.account_tree);
          }
          if (latestAct is ActiveAct || latestAct is PausedAct) {
            return _alongAct(
              context,
              ref,
              memId,
              latestAct,
              enableSkip: false,
            );
          }
          return MemDoneCheckbox(_mem, doneEdit.onChanged);
        },
        {'_mem': _mem},
      );

  Widget _alongAct(
    BuildContext context,
    WidgetRef ref,
    int memId,
    Act? latestAct, {
    required bool enableSkip,
  }) {
    if (latestAct is ActiveAct) {
      return _iconButton(
        Icons.pause,
        () => _acts(ref).pauseByMemId(memId),
      );
    }
    if (latestAct is PausedAct) {
      return _iconButton(
        Icons.close,
        () => _acts(ref).closeByMemId(memId),
      );
    }
    return _stopButton(
      context,
      ref,
      memId,
      enableSkip: enableSkip,
    );
  }
}

class TrailingIconButton extends ConsumerWidget {
  final Mem _mem;

  const TrailingIconButton(this._mem, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final memId = _mem.id as int;
          final latestAct = _mem.latestAct;
          if (latestAct is ActiveAct) {
            return _stopButton(
              context,
              ref,
              memId,
              enableSkip: false,
            );
          }
          if (latestAct is PausedAct) {
            return _iconButton(
              Icons.play_arrow,
              () => _acts(ref).resumeActBy(memId),
            );
          }
          return _iconButton(
            Icons.play_arrow,
            () => _acts(ref).startActby(memId),
          );
        },
        {'_mem': _mem},
      );
}

Widget? trailingIconButton(WidgetRef ref, Mem mem) {
  final hasNotifications = _hasEnabledNotifications(ref, mem.id as int);
  final hasUndoneChildren = _hasUndoneChildren(ref, mem.id);
  if (mem.isDone || (!hasNotifications && hasUndoneChildren)) {
    return null;
  }
  return TrailingIconButton(mem);
}

ActEntities _acts(WidgetRef ref) => ref.read(actEntitiesProvider.notifier);

bool hasEnabledMemNotifications(
  Iterable<MemNotificationEntityV1> notifications,
) =>
    notifications
        .where(
          (e) => e is SavedMemNotificationEntityV1 && e.value.isEnabled(),
        )
        .isNotEmpty;

bool _hasEnabledNotifications(WidgetRef ref, int memId) =>
    hasEnabledMemNotifications(
      ref.watch(memNotificationsByMemIdProvider(memId)),
    );

bool _hasUndoneChildren(WidgetRef ref, MemId memId) => ref.watch(
      parentMemIdsWithUndoneChildrenProvider.select(
        (ids) => ids.contains(memId),
      ),
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

Widget _iconButton(IconData icon, void Function() onPressed) => IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
    );

Widget _stopButton(
  BuildContext context,
  WidgetRef ref,
  int memId, {
  required bool enableSkip,
}) {
  void finish() => _acts(ref).finishActby(memId);
  void skip() => _acts(ref).skipActBy(memId);
  return memListCompletionStopButton(
    context: context,
    onFinish: finish,
    enableSkipMenu: enableSkip,
    onShowCompletionDialog: (dialogContext) {
      showMemListCompletionDialog(
        dialogContext,
        onFinish: finish,
        onSkip: skip,
      );
    },
  );
}
