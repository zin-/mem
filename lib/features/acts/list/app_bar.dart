import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/period_menu_item.dart';
import 'package:mem/features/acts/period_view.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/states.dart';
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
          (Period unit) => ref.read(dateViewProvider.notifier).updatedBy(unit),
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
  final Period _group;
  final void Function(Period unit) _changeGroup;
  final bool _isTimeView;
  final void Function(bool changed) _changeTimeViewMode;

  const _ActListAppBar(
    this._title,
    this._group,
    this._changeGroup,
    this._isTimeView,
    this._changeTimeViewMode,
  );

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: Text(_title),
          actions: [
            PopupMenuButton<Period>(
              tooltip: buildL10n(context).timePeriod,
              onSelected: (unit) => v(
                () => _changeGroup(unit),
                {
                  '_group': _group,
                  'unit': unit,
                },
              ),
              icon: Icon(_group.icon),
              itemBuilder: (context) => [
                for (final unit in Period.values)
                  PeriodMenuItem(
                    period: unit,
                    selected: _group,
                  ),
              ],
            ),
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
          "_group": _group,
          "_isTimeView": _isTimeView,
        },
      );
}
