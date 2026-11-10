import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_parents/mem_parent.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
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
          final parentMemId = mem.parentMemId;
          final parentName = parentMemId == null
              ? null
              : _entityById(entities, parentMemId)?.name;
          final childrenNames = <String>[];
          for (final childId in mem.childMemIds) {
            final name = _entityById(entities, childId)?.name;
            if (name != null) childrenNames.add(name);
          }
          childrenNames.sort();

          return _MemParentSection(
            parentName: parentName,
            childrenNames: childrenNames,
            onSet: () => _setParent(context, ref, _memId),
            onDisconnect: parentMemId == null
                ? null
                : () => _disconnectParent(context, ref, _memId),
          );
        },
        _memId,
      );
}

class _MemParentSection extends StatelessWidget {
  final String? _parentName;
  final List<String> _childrenNames;
  final VoidCallback _onSet;
  final VoidCallback? _onDisconnect;

  const _MemParentSection({
    required String? parentName,
    required List<String> childrenNames,
    required VoidCallback onSet,
    required VoidCallback? onDisconnect,
  })  : _parentName = parentName,
        _childrenNames = childrenNames,
        _onSet = onSet,
        _onDisconnect = onDisconnect;

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_tree),
                title: Text(_parentName ?? l10n.parentNone),
                onTap: _onSet,
                trailing: _onDisconnect == null
                    ? null
                    : IconButton(
                        onPressed: _onDisconnect,
                        tooltip: l10n.disconnectParentAction,
                        icon: const Icon(Icons.close),
                      ),
              ),
              for (final name in _childrenNames)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.subdirectory_arrow_right),
                  title: Text(name),
                ),
            ],
          );
        },
        {
          'parentName': _parentName,
          'childrenNames': _childrenNames,
        },
      );
}

Future<void> _setParent(BuildContext context, WidgetRef ref, int memId) => v(
      () async {
        final mems = await MemRepository().ship();
        final excludedIds = await _excludedParentCandidateIds(memId);
        final currentParent = await MemRepository().shipParentByMemId(memId);
        if (!context.mounted) return;

        final candidates = mems
            .where((mem) => !excludedIds.contains(mem.id))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        final selectedId = await showDialog<int>(
          context: context,
          builder: (context) => _SelectParentDialog(
            candidates: candidates,
            currentParentMemId: currentParent?.parentMemId,
          ),
        );
        if (selectedId == null || !context.mounted) return;

        try {
          await MemRepository().replaceParent(
            MemParent(memId: memId, parentMemId: selectedId),
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
          nextParentMemId: selectedId,
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
  int memId,
) =>
    v(
      () async {
        final previousParentMemId =
            ref.read(memByMemIdProvider(memId))?.parentMemId;
        await MemRepository().wasteParents(memId: memId);
        if (!context.mounted) return;
        await _reloadParentDetails(
          ref,
          memId: memId,
          previousParentMemId: previousParentMemId,
        );
      },
      memId,
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
  await ref.read(parentMemIdsWithOpenChildrenProvider.notifier).refresh();
}

MemEntity? _entityById(Iterable<MemEntity> entities, int id) {
  for (final entity in entities) {
    if (entity.id == id) return entity;
  }
  return null;
}

class _SelectParentDialog extends StatelessWidget {
  final List<MemEntity> _candidates;
  final int? _currentParentMemId;

  const _SelectParentDialog({
    required List<MemEntity> candidates,
    required int? currentParentMemId,
  })  : _candidates = candidates,
        _currentParentMemId = currentParentMemId;

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return AlertDialog(
            title: Text(l10n.selectParentTitle),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.sizeOf(context).height / 2,
              child: ListView.builder(
                itemCount: _candidates.length,
                itemBuilder: (context, index) {
                  final mem = _candidates[index];
                  final isCurrentParent = mem.id == _currentParentMemId;
                  return ListTile(
                    title: Text(mem.name),
                    enabled: !isCurrentParent,
                    onTap: isCurrentParent
                        ? null
                        : () => Navigator.of(context).pop(mem.id),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancelAction),
              ),
            ],
          );
        },
        {
          'candidates': _candidates,
          'currentParentMemId': _currentParentMemId,
        },
      );
}
