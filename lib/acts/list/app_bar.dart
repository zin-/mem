import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/list/states.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/values/constants.dart';

class ActListAppBar extends ConsumerWidget {
  final int? _memId;

  const ActListAppBar(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _ActListAppBar(
          _memId == null
              ? buildL10n(context).actListPageTitle
              : ref.watch(memProvider(_memId!))?.name ?? somethingWrong,
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
  final String _title;
  final IconButton _viewModeToggle;

  const _ActListAppBar(this._title, this._viewModeToggle);

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: Text(_title),
          actions: [
            _viewModeToggle,
          ],
          floating: true,
        ),
        {_title, _viewModeToggle},
      );
}
