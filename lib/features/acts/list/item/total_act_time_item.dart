import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_count_label.dart';
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

    final range = _actListRange(_actList.map((act) => act.value));

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
                ..._timeTargetSuffix(),
              ],
            ),
            ActCountLabel(
              _actList.length,
              _targetAmount(TargetUnit.count),
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

  int? _targetAmount(TargetUnit unit) {
    final target = _targetEntity?.value;
    if (target == null || target.targetUnit != unit) {
      return null;
    }
    return target.value;
  }

  List<Widget> _timeTargetSuffix() {
    final amount = _targetAmount(TargetUnit.time);
    if (amount == null) {
      return const [];
    }
    return [
      const Text(" / "),
      Text(Duration(seconds: amount).formatHHmm()),
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

DateAndTimePeriod? _actListRange(Iterable<Act> acts) {
  final started = [
    for (final act in acts)
      if (act.period?.start != null) act,
  ];
  if (started.isEmpty) {
    return null;
  }

  final earliest = started
      .map((act) => act.period!.start!)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final latest = started.reduce(_laterEnd);
  final end = _endCandidate(latest);

  // 実行中の開始が最初と同時なら終了側は空（10:00 ~）
  if (latest.isActive && !end.isAfter(earliest)) {
    return DateAndTimePeriod(start: earliest);
  }
  return DateAndTimePeriod(start: earliest, end: end);
}

DateAndTime _endCandidate(Act act) => act.period!.end ?? act.period!.start!;

Act _laterEnd(Act current, Act next) {
  final compared = _endCandidate(next).compareTo(_endCandidate(current));
  // 同時刻なら実行中を採用し、終了済みの終了より後の開始として見せる
  if (compared > 0 || (compared == 0 && next.isActive)) {
    return next;
  }
  return current;
}
