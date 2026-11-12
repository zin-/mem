import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/targets/target.dart';

import '../act_list_group.dart';
import '../act_list_view.dart';
import 'total_act_time_item.dart';
import 'view.dart';

class ActListItemBuilder {
  final MapEntry<ActListGroup, List<SavedActEntityV1>> _groupedActs;
  final List<Mem> _memList;
  final ActListView _view;
  final List<Target> _targetList;

  late final Map<int, List<SavedActEntityV1>> _actListGroupedByMemId;

  ActListItemBuilder(
    this._groupedActs,
    this._memList,
    this._view,
    this._targetList,
  ) {
    if (_view == ActListView.totalTime) {
      _actListGroupedByMemId =
          _groupedActs.value.groupListsBy((element) => element.value.memId);
    }
  }

  Widget? build(BuildContext context, int index) => v(
        () {
          if (_view == ActListView.totalTime) {
            final entry = _actListGroupedByMemId.entries.toList()[index];

            return TotalActTimeListItem(
              entry.value,
              _memList.singleWhereOrNull((mem) => mem.id! == entry.key),
              _targetList.singleWhereOrNull((e) => e.memId == entry.key),
              _groupedActs.key,
            );
          } else {
            final act = _groupedActs.value[index];
            return ActListItemView(
              act,
              _memList
                  .singleWhereOrNull((mem) => mem.id! == act.value.memId)
                  ?.name,
            );
          }
        },
        {
          'context': context,
          'index': index,
        },
      );

  int get childCount => _view == ActListView.totalTime
      ? _actListGroupedByMemId.length
      : _groupedActs.value.length;
}
