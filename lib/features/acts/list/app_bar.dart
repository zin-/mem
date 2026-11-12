import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/period_menu_item.dart';
import 'package:mem/features/acts/period_view.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/values/constants.dart';

import 'act_list_view.dart';

class ActListAppBar extends ConsumerWidget {
  final int? _memId;
  final Period _groupUnit;
  final void Function(Period unit) _changeGroupUnit;
  final ActListView _view;
  final void Function(ActListView view) _changeView;

  const ActListAppBar(
    this._memId,
    this._groupUnit,
    this._changeGroupUnit,
    this._view,
    this._changeView, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _ActListAppBar(
          _memId == null
              ? buildL10n(context).defaultActListPageTitle
              : ref.read(memByMemIdProvider(_memId))?.name ?? somethingWrong,
          _groupUnit,
          _changeGroupUnit,
          _view,
          _changeView,
        ),
        {
          "_memId": _memId,
          "_groupUnit": _groupUnit,
          "_view": _view,
        },
      );
}

class _ActListAppBar extends StatelessWidget {
  final String _title;
  final Period _group;
  final void Function(Period unit) _changeGroup;
  final ActListView _view;
  final void Function(ActListView view) _changeView;

  const _ActListAppBar(
    this._title,
    this._group,
    this._changeGroup,
    this._view,
    this._changeView,
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
                () => _changeView(_view.toggled()),
                {"_view": _view},
              ),
              icon: Icon(
                _view == ActListView.totalTime
                    ? Icons.numbers
                    : Icons.access_time,
              ),
            )
          ],
        ),
        {
          "_title": _title,
          "_group": _group,
          "_view": _view,
        },
      );
}
