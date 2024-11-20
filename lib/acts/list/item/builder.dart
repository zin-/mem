import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/acts/act_entity.dart';
import 'package:mem/mems/mem_entity.dart';

import 'total_act_time_item.dart';
import 'view.dart';

class ActListItemBuilder {
  final MapEntry<DateTime, List<Act>> _actListWithDatetime;
  final List<SavedMemEntity> _memList;
  final bool _isTimeView;

  late final Map _actListGroupedByMemId;

  ActListItemBuilder(
    this._actListWithDatetime,
    this._memList,
    this._isTimeView,
  ) {
    if (_isTimeView) {
      _actListGroupedByMemId =
          _actListWithDatetime.value.groupListsBy((element) => element.memId);
    }
  }

  Widget? build(BuildContext context, int index) => v(
        () {
          if (_isTimeView) {
            final entry = _actListGroupedByMemId.entries.toList()[index];

            return TotalActTimeListItem(
              entry.value,
              _memList.singleWhereOrNull((element) => element.id == entry.key),
            );
          } else {
            final act = _actListWithDatetime.value[index];
            if (act is SavedActEntity) {
              return ActListItemView(
                act,
                _memList
                    .singleWhereOrNull((element) => element.id == act.memId)
                    ?.name,
              );
            } else {
              return null;
            }
          }
        },
        {
          "context": context,
          "index": index,
        },
      );

  int get childCount => _isTimeView
      ? _actListGroupedByMemId.length
      : _actListWithDatetime.value.length;
}
