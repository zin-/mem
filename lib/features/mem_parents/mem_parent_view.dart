import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_parents/mem_parent.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_select_dialog.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/l10n/l10n.dart';

class MemParentView extends ConsumerWidget {
  final int _memId;

  const MemParentView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.watch(memByMemIdProvider(_memId));
          if (mem == null || !mem.parentsLoaded) {
            return const CircularProgressIndicator();
          }

          final entities = ref.watch(memEntitiesProvider);

          Mem? memById(int? id) {
            if (id == null) return null;
            return _entityById(entities, id)?.toDomain();
          }

          final parent = memById(mem.parentMemId);
          final children = <Mem>[
            for (final childId in mem.childMemIds)
              if (memById(childId) case final child?) child,
          ]..sort((a, b) => a.name.compareTo(b.name));

          void disconnect(int memId) {
            if (memId == _memId) {
              _disconnectParent(context, ref, memId);
              return;
            }
            _disconnectParent(
              context,
              ref,
              memId,
              previousParentMemId: _memId,
            );
          }

          return _MemParentSection(
            memId: _memId,
            parent: parent,
            children: children,
            onOpen: (memId) => showMemDetailPage(context, ref, memId),
            onDisconnect: disconnect,
            onSetParent: () => _setParent(context, ref, _memId),
          );
        },
        _memId,
      );
}

class _MemParentSection extends StatelessWidget {
  final int _memId;
  final Mem? _parent;
  final List<Mem> _children;
  final void Function(int memId) _onOpen;
  final void Function(int memId) _onDisconnect;
  final VoidCallback _onSetParent;

  const _MemParentSection({
    required int memId,
    required Mem? parent,
    required List<Mem> children,
    required void Function(int memId) onOpen,
    required void Function(int memId) onDisconnect,
    required VoidCallback onSetParent,
  })  : _memId = memId,
        _parent = parent,
        _children = children,
        _onOpen = onOpen,
        _onDisconnect = onDisconnect,
        _onSetParent = onSetParent;

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          final parent = _parent;
          final parentId = parent?.id;

          ListTile memRow({
            required IconData icon,
            required String name,
            required VoidCallback onTap,
            VoidCallback? onDisconnect,
          }) =>
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon),
                title: Text(name),
                onTap: onTap,
                trailing: onDisconnect == null
                    ? null
                    : IconButton(
                        onPressed: onDisconnect,
                        tooltip: l10n.disconnectParentAction,
                        icon: const Icon(Icons.close),
                      ),
              );

          return Column(
            children: [
              memRow(
                icon: Icons.account_tree,
                name: parent?.name ?? l10n.parentNone,
                onTap:
                    parentId == null ? _onSetParent : () => _onOpen(parentId),
                onDisconnect:
                    parentId == null ? null : () => _onDisconnect(_memId),
              ),
              for (final child in _children)
                if (child.id case final int childId)
                  memRow(
                    icon: Icons.subdirectory_arrow_right,
                    name: child.name,
                    onTap: () => _onOpen(childId),
                    onDisconnect: () => _onDisconnect(childId),
                  ),
            ],
          );
        },
        {
          'memId': _memId,
          'parent': _parent,
          'children': _children,
        },
      );
}

Future<void> _setParent(BuildContext context, WidgetRef ref, int memId) => v(
      () async {
        final mems = await MemRepository().ship(archived: false);
        final excludedIds = await _excludedParentCandidateIds(memId);
        final currentParent = await MemRepository().shipParentByMemId(memId);
        if (!context.mounted) return;

        final candidates = mems..sort((a, b) => a.name.compareTo(b.name));
        final l10n = buildL10n(context);
        int? selectedId;
        await showDialog<void>(
          context: context,
          builder: (context) => MemSelectDialog(
            candidates: candidates,
            mode: MemSelectMode.single,
            excludedMemIds: excludedIds,
            selectedMemIds: const [],
            title: l10n.selectParentTitle,
            confirmLabel: l10n.okAction,
            cancelLabel: l10n.cancelAction,
            onSubmit: (ids) {
              if (ids.isEmpty) return;
              selectedId = ids.single;
            },
          ),
        );
        final chosenId = selectedId;
        if (chosenId == null || !context.mounted) return;

        try {
          await MemRepository().replaceParent(
            MemParent(memId: memId, parentMemId: chosenId),
          );
        } on ArgumentError {
          // 循環のときは replaceParent が拒否し、今の親を残す
          return;
        }
        if (!context.mounted) return;
        await _reloadParentDetails(
          ref,
          memId: memId,
          previousParentMemId: currentParent?.parentMemId,
          nextParentMemId: chosenId,
        );
      },
      memId,
    );

Future<Set<int>> _excludedParentCandidateIds(int memId) => v(
      () async {
        final excluded = <int>{memId};
        final pending = <int>[memId];
        while (pending.isNotEmpty) {
          final current = pending.removeLast();
          final children =
              await MemRepository().shipChildrenByParentMemId(current);
          for (final child in children) {
            if (excluded.add(child.memId)) {
              pending.add(child.memId);
            }
          }
        }
        return excluded;
      },
      memId,
    );

Future<void> _disconnectParent(
  BuildContext context,
  WidgetRef ref,
  int memId, {
  int? previousParentMemId,
}) =>
    v(
      () async {
        final parentMemId = previousParentMemId ??
            ref.read(memByMemIdProvider(memId))?.parentMemId;
        await MemRepository().wasteParents(memId: memId);
        if (!context.mounted) return;
        await _reloadParentDetails(
          ref,
          memId: memId,
          previousParentMemId: parentMemId,
        );
      },
      {
        'memId': memId,
        'previousParentMemId': previousParentMemId,
      },
    );

Future<void> _reloadParentDetails(
  WidgetRef ref, {
  required int memId,
  int? previousParentMemId,
  int? nextParentMemId,
}) async {
  final entities = ref.read(memEntitiesProvider);
  final ids = <int>[memId];
  for (final parentId in [previousParentMemId, nextParentMemId]) {
    if (parentId == null || ids.contains(parentId)) continue;
    final cached = _entityById(entities, parentId);
    if (cached != null && cached.parentsLoaded) {
      ids.add(parentId);
    }
  }
  final notifier = ref.read(memEntitiesProvider.notifier);
  await Future.wait([
    for (final id in ids) notifier.loadDetail(id),
  ]);
  await ref.read(parentMemIdsWithUndoneChildrenProvider.notifier).refresh();
}

MemEntity? _entityById(Iterable<MemEntity> entities, int id) {
  for (final entity in entities) {
    if (entity.id == id) return entity;
  }
  return null;
}
