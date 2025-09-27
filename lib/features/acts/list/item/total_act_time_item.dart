import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';

class TotalActTimeListItem extends StatelessWidget {
  final List<SavedActEntity> _actList;
  final SavedMemEntity? _memEntity;
  final SavedTargetEntity? _targetEntity;

  const TotalActTimeListItem(
    this._actList,
    this._memEntity,
    this._targetEntity, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          final active = _actList.firstWhereOrNull(
            (e) => e.value.isActive,
          );

          return ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(children: [
                  if (active != null)
                    Text((_actList.fold<Duration>(
                              Duration.zero,
                              (previousValue, element) =>
                                  previousValue +
                                  (element.value.period?.duration ??
                                      Duration.zero),
                            ) +
                            DateTime.now()
                                .difference(active.value.period!.start!))
                        .formatHHmm()),
                  if (active != null) Text(" / "),
                  Text(_actList
                      .fold<Duration>(
                        Duration.zero,
                        (previousValue, element) =>
                            previousValue +
                            (element.value.period?.duration ?? Duration.zero),
                      )
                      .formatHHmm()),
                  if (_targetEntity != null &&
                      _targetEntity.value.targetUnit == TargetUnit.time)
                    Text(" / "),
                  if (_targetEntity != null &&
                      _targetEntity.value.targetUnit == TargetUnit.time)
                    Text(
                      Duration(seconds: _targetEntity.value.value).formatHHmm(),
                    ),
                ]),
                Wrap(
                  children: [
                    Text(_actList.length.toString()),
                    if (_targetEntity != null &&
                        _targetEntity.value.targetUnit == TargetUnit.count)
                      Text(" / "),
                    if (_targetEntity != null &&
                        _targetEntity.value.targetUnit == TargetUnit.count)
                      Text(_targetEntity.value.value.toString()),
                  ],
                ),
              ],
            ),
            subtitle: _memEntity == null ? null : Text(_memEntity.value.name),
            trailing: _memEntity == null
                ? null
                : IconButton(
                    onPressed: () =>
                        showMemDetailPage(context, null, _memEntity.id),
                    icon: const Icon(Icons.arrow_forward),
                  ),
          );
        },
        {
          '_actList': _actList,
          '_mem': _memEntity,
        },
      );
}
