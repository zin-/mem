import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/targets/target_entity.dart';

import 'total_act_time_item.dart';
import 'view.dart';

class ActListItemBuilder {
  final MapEntry<DateTime, List<SavedActEntity>> _actListWithDatetime;
  final List<SavedMemEntity> _memList;
  final bool _isTimeView;
  final List<SavedTargetEntity> _targetList;

  late final Map<int, List<SavedActEntity>> _actListGroupedByMemId;

  ActListItemBuilder(
    this._actListWithDatetime,
    this._memList,
    this._isTimeView,
    this._targetList,
  ) {
    if (_isTimeView) {
      _actListGroupedByMemId = _actListWithDatetime.value
          .groupListsBy((element) => element.value.memId);
    }
  }

  Widget? build(BuildContext context, int index) => v(
        () {
          if (_isTimeView) {
            final entry = _actListGroupedByMemId.entries.toList()[index];

            return TotalActTimeListItem(
              entry.value,
              _memList.singleWhereOrNull((element) => element.id == entry.key),
              _targetList.singleWhereOrNull((e) => e.value.memId == entry.key),
            );
          } else {
            final act = _actListWithDatetime.value[index];
            return ActListItemView(
              act,
              _memList
                  .singleWhereOrNull((element) => element.id == act.value.memId)
                  ?.value
                  .name,
            );
          }
        },
        {
          'context': context,
          'index': index,
        },
      );

  int get childCount => _isTimeView
      ? _actListGroupedByMemId.length
      : _actListWithDatetime.value.length;
}
