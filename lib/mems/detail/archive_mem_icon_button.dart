import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/nullable_widget_builder.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/values/durations.dart';

class ArchiveMemIconButton extends ConsumerWidget {
  final int? _memId;

  const ArchiveMemIconButton(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.watch(memByMemIdProvider(_memId));

          if (mem is SavedMem) {
            if (mem.isArchived) {
              return _UnarchiveMemIconButton(
                mem.name,
                () => ref.read(unarchiveMem(_memId!)),
              );
            } else {
              return _ArchiveMemIconButton(
                mem.name,
                () => ref.read(archiveMem(_memId!)),
              );
            }
          } else {
            return nullableWidget;
          }
        },
      );
}

class _UnarchiveMemIconButton extends StatelessWidget {
  final String memName;
  final Future<MemDetail?> Function() _unarchiveMem;

  const _UnarchiveMemIconButton(this.memName, this._unarchiveMem);

  @override
  Widget build(BuildContext context) => v(
        () => IconButton(
          icon: const Icon(Icons.unarchive),
          onPressed: () {
            // TODO unarchiveしたときにAppBarの色が変わらない
            _unarchiveMem();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(buildL10n(context).unarchiveMemSuccessMessage(
                  memName,
                )),
                duration: defaultDismissDuration,
                dismissDirection: DismissDirection.horizontal,
              ),
            );
          },
        ),
        {"memName": memName},
      );
}

class _ArchiveMemIconButton extends StatelessWidget {
  final String memName;
  final Future<MemDetail?> Function() _archiveMem;

  const _ArchiveMemIconButton(this.memName, this._archiveMem);

  @override
  Widget build(BuildContext context) => v(
        () => IconButton(
          icon: const Icon(Icons.archive),
          onPressed: () {
            _archiveMem();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  buildL10n(context).archiveMemSuccessMessage(
                    memName,
                  ),
                ),
                duration: defaultDismissDuration,
                dismissDirection: DismissDirection.horizontal,
              ),
            );

            Navigator.of(context).pop(null);
          },
        ),
        {"memName": memName},
      );
}
