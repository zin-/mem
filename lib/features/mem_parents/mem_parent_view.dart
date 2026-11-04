import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_parents/mem_parent.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/l10n/l10n.dart';

final parentNameByMemIdProvider =
    FutureProvider.autoDispose.family<String?, int>((ref, memId) {
  return v(
    () async {
      final parent = await MemRepository().shipParentByMemId(memId);
      if (parent == null) return null;
      final mem = await MemRepository().shipById(parent.parentMemId);
      return mem.name;
    },
    memId,
  );
});

final childrenNamesByMemIdProvider =
    FutureProvider.autoDispose.family<List<String>, int>((ref, memId) {
  return v(
    () async {
      final children = await MemRepository().shipChildrenByParentMemId(memId);
      final names = <String>[];
      for (final child in children) {
        final mem = await MemRepository().shipById(child.memId);
        names.add(mem.name);
      }
      names.sort();
      return names;
    },
    memId,
  );
});

class MemParentView extends ConsumerWidget {
  final int _memId;

  const MemParentView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final parentName = ref.watch(parentNameByMemIdProvider(_memId));
          final childrenNames = ref.watch(childrenNamesByMemIdProvider(_memId));

          return parentName.when(
            data: (name) => childrenNames.when(
              data: (names) => _MemParentSection(
                parentName: name,
                childrenNames: names,
                onSet: () => _setParent(context, ref, _memId),
                onDisconnect: name == null
                    ? null
                    : () => _disconnectParent(context, ref, _memId),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stackTrace) => const Text('Error'),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stackTrace) => const Text('Error'),
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
        if (!context.mounted) return;

        final candidates = mems
            .where((mem) => !excludedIds.contains(mem.id))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        final selectedId = await showDialog<int>(
          context: context,
          builder: (context) => _SelectParentDialog(candidates: candidates),
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
        ref.invalidate(parentNameByMemIdProvider(memId));
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
        await MemRepository().wasteParents(memId: memId);
        if (!context.mounted) return;
        ref.invalidate(parentNameByMemIdProvider(memId));
      },
      memId,
    );

class _SelectParentDialog extends StatelessWidget {
  final List<MemEntity> _candidates;

  const _SelectParentDialog({required List<MemEntity> candidates})
      : _candidates = candidates;

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
                  return ListTile(
                    title: Text(mem.name),
                    onTap: () => Navigator.of(context).pop(mem.id),
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
        _candidates,
      );
}
