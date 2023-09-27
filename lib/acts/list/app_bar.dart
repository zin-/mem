import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/list/states.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/states.dart';

class ActListAppBar extends ConsumerWidget {
  final int? _memId;

  const ActListAppBar(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _ActListAppBar(
          _memId == null
              ? null
              : ref
                  .watch(memsProvider)
                  ?.singleWhereOrNull((element) => element.id == _memId)
                  ?.name,
          IconButton(
            icon: Icon(
              ref.watch(timeViewProvider) ? Icons.numbers : Icons.access_time,
            ),
            onPressed: () => ref
                .read(timeViewProvider.notifier)
                .updatedBy(!ref.read(timeViewProvider)),
          ),
        ),
        _memId,
      );
}

class _ActListAppBar extends StatelessWidget {
  final String? _memName;
  final IconButton _viewModeToggle;

  const _ActListAppBar(this._memName, this._viewModeToggle);

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: Text(_memName ?? buildL10n(context).actListPageTitle),
          actions: [
            _viewModeToggle,
          ],
          floating: true,
        ),
        {_memName, _viewModeToggle},
      );
}
