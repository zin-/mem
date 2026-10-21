import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/features/acts/states.dart';
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
  final DateTime _groupDate;
  final bool _isDateView;

  const TotalActTimeListItem(
    this._actList,
    this._mem,
    this._targetEntity,
    this._groupDate,
    this._isDateView, {
    super.key,
  });

  bool _isCurrentPeriod(DateTime now) {
    final sameMonth =
        _groupDate.year == now.year && _groupDate.month == now.month;
    if (!_isDateView) {
      return sameMonth;
    }
    return sameMonth && _groupDate.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final active = _actList.firstWhereOrNull(
            (e) => e.value.isActive,
          );
          final actMemId = _actList.first.value.memId;
          final loadedMem = ref.watch(memByMemIdProvider(_mem?.id ?? actMemId));
          final int memId = _mem?.id ?? loadedMem?.id ?? actMemId;
          // 実行中が前日始まりでも、今の行のボタンがずれないように期間内 Act は見ない
          final latestAct =
              loadedMem != null ? loadedMem.latestAct : _mem?.latestAct;
          final showActions = _isCurrentPeriod(DateTime.now());

          IconButton actionButton(IconData icon, void Function() onPressed) =>
              IconButton(
                onPressed: onPressed,
                icon: Icon(icon),
              );

          final Widget? leading;
          final Widget? trailing;
          if (!showActions) {
            leading = null;
            trailing = null;
          } else if (latestAct is ActiveAct) {
            leading = actionButton(
              Icons.pause,
              () => ref.read(actEntitiesProvider.notifier).pauseByMemId(memId),
            );
            trailing = actionButton(
              Icons.stop,
              () => ref.read(actEntitiesProvider.notifier).finishActby(memId),
            );
          } else if (latestAct is PausedAct) {
            leading = actionButton(
              Icons.close,
              () => ref.read(actEntitiesProvider.notifier).closeByMemId(memId),
            );
            trailing = actionButton(
              Icons.play_arrow,
              () => ref.read(actEntitiesProvider.notifier).resumeActBy(memId),
            );
          } else {
            leading = actionButton(
              Icons.stop,
              () => ref.read(actEntitiesProvider.notifier).finishActby(memId),
            );
            trailing = actionButton(
              Icons.play_arrow,
              () => ref.read(actEntitiesProvider.notifier).startActby(memId),
            );
          }

          return ListTile(
            leading: leading,
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
            trailing: trailing,
            onTap: () => showMemDetailPage(context, ref, memId),
          );
        },
        {
          '_actList': _actList,
          '_mem': _mem,
          '_groupDate': _groupDate,
          '_isDateView': _isDateView,
        },
      );
}
