import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';

class TotalActTimeListItem extends ConsumerWidget {
  final List<SavedActEntityV1> _actList;
  final Mem? _mem;
  final SavedTargetEntityV1? _targetEntity;

  const TotalActTimeListItem(
    this._actList,
    this._mem,
    this._targetEntity, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final active = _actList.firstWhereOrNull(
            (e) => e.value.isActive,
          );
          final actMemId = _actList.first.value.memId;
          final loadedMemId =
              ref.watch(memByMemIdProvider(_mem?.id ?? actMemId))?.id;
          final memId = _mem?.id ?? loadedMemId ?? actMemId;

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
            subtitle: _mem == null ? null : Text(_mem.name),
            onTap: () => showMemDetailPage(context, ref, memId),
          );
        },
        {
          '_actList': _actList,
          '_mem': _mem,
        },
      );
}
