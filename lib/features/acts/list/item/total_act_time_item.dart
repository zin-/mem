import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
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
          final actMemId = _actList.first.value.memId;
          final loadedMem = ref.watch(
            memByMemIdProvider(_mem?.id ?? actMemId),
          );
          final memId = _mem?.id ?? loadedMem?.id ?? actMemId;
          // 実行中が前日始まりでも、今の行のボタンがずれないように期間内 Act は見ない
          final latestAct =
              loadedMem != null ? loadedMem.latestAct : _mem?.latestAct;
          final actions = _isCurrentPeriod(DateTime.now())
              ? _actions(ref, memId, latestAct)
              : (leading: null, trailing: null);

          return ListTile(
            leading: actions.leading,
            title: _title(),
            subtitle: _mem == null ? null : Text(_mem.name),
            trailing: actions.trailing,
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

  Widget _title() {
    final active = _actList.firstWhereOrNull((act) => act.value.isActive);
    final recorded = _actList.fold<Duration>(
      Duration.zero,
      (sum, act) => sum + (act.value.period?.duration ?? Duration.zero),
    );
    final elapsed = active == null
        ? null
        : recorded + DateTime.now().difference(active.value.period!.start!);

    final range = _rangePeriod();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              children: [
                if (elapsed != null) ...[
                  Text(elapsed.formatHHmm()),
                  const Text(" / "),
                ],
                Text(recorded.formatHHmm()),
                ..._targetSuffix(TargetUnit.time),
              ],
            ),
            Wrap(
              children: [
                Text(_actList.length.toString()),
                ..._targetSuffix(TargetUnit.count),
              ],
            ),
          ],
        ),
        if (range != null)
          DateAndTimePeriodTexts(
            range,
            showDate: !_isDateView,
          ),
      ],
    );
  }

  DateAndTimePeriod? _rangePeriod() {
    DateAndTime? earliestStart;
    DateAndTime? latestPoint;
    var latestIsOpenStart = false;

    for (final act in _actList) {
      final period = act.value.period;
      final start = period?.start;
      if (start == null) {
        continue;
      }
      final end = period?.end;
      final point = end ?? start;

      if (earliestStart == null || start.compareTo(earliestStart) < 0) {
        earliestStart = start;
      }
      if (latestPoint == null || point.compareTo(latestPoint) > 0) {
        latestPoint = point;
        latestIsOpenStart = end == null;
      } else if (point.compareTo(latestPoint) == 0 && end == null) {
        latestIsOpenStart = true;
      }
    }

    if (earliestStart == null || latestPoint == null) {
      return null;
    }

    // 実行中の開始が最初と同時なら終了側は空（10:00 ~）
    if (latestIsOpenStart && latestPoint.compareTo(earliestStart) == 0) {
      return DateAndTimePeriod(start: earliestStart);
    }
    return DateAndTimePeriod(start: earliestStart, end: latestPoint);
  }

  List<Widget> _targetSuffix(TargetUnit unit) {
    final target = _targetEntity?.value;
    if (target == null || target.targetUnit != unit) {
      return const [];
    }

    final label = switch (unit) {
      TargetUnit.time => Duration(seconds: target.value).formatHHmm(),
      TargetUnit.count => target.value.toString(),
    };
    return [
      const Text(" / "),
      Text(label),
    ];
  }

  ({Widget? leading, Widget? trailing}) _actions(
    WidgetRef ref,
    int memId,
    Act? latestAct,
  ) {
    IconButton button(IconData icon, void Function() onPressed) => IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
        );

    ActEntities acts() => ref.read(actEntitiesProvider.notifier);

    return switch (latestAct) {
      ActiveAct() => (
          leading: button(Icons.pause, () => acts().pauseByMemId(memId)),
          trailing: button(Icons.stop, () => acts().finishActby(memId)),
        ),
      PausedAct() => (
          leading: button(Icons.close, () => acts().closeByMemId(memId)),
          trailing: button(Icons.play_arrow, () => acts().resumeActBy(memId)),
        ),
      _ => (
          leading: button(Icons.stop, () => acts().finishActby(memId)),
          trailing: button(Icons.play_arrow, () => acts().startActby(memId)),
        ),
    };
  }
}
