import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/values/constants.dart';

import 'states.dart';

class ActListAppBar extends ConsumerWidget {
  final int? _memId;

  const ActListAppBar(
    this._memId, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _ActListAppBar(
          _memId == null
              ? buildL10n(context).defaultActListPageTitle
              : ref.read(memByMemIdProvider(_memId))?.name ?? somethingWrong,
          ref.watch(dateViewProvider),
          (bool changed) =>
              ref.read(dateViewProvider.notifier).updatedBy(changed),
          ref.watch(timeViewProvider),
          (bool changed) =>
              ref.read(timeViewProvider.notifier).updatedBy(changed),
        ),
        {
          "_memId": _memId,
        },
      );
}

class _ActListAppBar extends StatelessWidget {
  final String _title;
  final bool _isDateView;
  final void Function(bool changed) _changeDateViewMode;
  final bool _isTimeView;
  final void Function(bool changed) _changeTimeViewMode;

  const _ActListAppBar(
    this._title,
    this._isDateView,
    this._changeDateViewMode,
    this._isTimeView,
    this._changeTimeViewMode,
  );

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: Text(_title),
          actions: [
            IconButton(
                onPressed: () => v(
                      () => _changeDateViewMode(!_isDateView),
                      {"_isDateView": _isDateView},
                    ),
                icon: Icon(
                  _isDateView
                      ? Icons.calendar_view_month
                      : Icons.calendar_view_day,
                )),
            IconButton(
              onPressed: () => v(
                () => _changeTimeViewMode(!_isTimeView),
                {"_isTimeView": _isTimeView},
              ),
              icon: Icon(
                _isTimeView ? Icons.numbers : Icons.access_time,
              ),
            )
          ],
        ),
        {
          "_title": _title,
          "_isDateView": _isDateView,
          "_isTimeView": _isTimeView,
        },
      );
}
