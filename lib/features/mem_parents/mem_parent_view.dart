import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_parents/mem_parent.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/l10n/l10n.dart';

final _parentNameByMemIdProvider =
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

class MemParentView extends ConsumerWidget {
  final int _memId;

  const MemParentView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final parentName = ref.watch(_parentNameByMemIdProvider(_memId));

          return parentName.when(
            data: (name) => _MemParentSection(
              parentName: name,
              onSet: () => _setParent(context, ref, _memId),
              onDisconnect: name == null
                  ? null
                  : () => _disconnectParent(context, ref, _memId),
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
  final VoidCallback _onSet;
  final VoidCallback? _onDisconnect;

  const _MemParentSection({
    required String? parentName,
    required VoidCallback onSet,
    required VoidCallback? onDisconnect,
  })  : _parentName = parentName,
        _onSet = onSet,
        _onDisconnect = onDisconnect;

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_tree),
                title: Text(l10n.parentLabel),
                subtitle: Text(_parentName ?? l10n.parentNone),
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: _onSet,
                    child: Text(l10n.setParentAction),
                  ),
                  if (_onDisconnect != null)
                    TextButton(
                      onPressed: _onDisconnect,
                      child: Text(l10n.disconnectParentAction),
                    ),
                ],
              ),
            ],
          );
        },
        _parentName,
      );
}

Future<void> _setParent(BuildContext context, WidgetRef ref, int memId) => v(
      () async {
        final mems = await MemRepository().ship();
        if (!context.mounted) return;

        final candidates = mems.where((mem) => mem.id != memId).toList()
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
        ref.invalidate(_parentNameByMemIdProvider(memId));
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
        ref.invalidate(_parentNameByMemIdProvider(memId));
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
