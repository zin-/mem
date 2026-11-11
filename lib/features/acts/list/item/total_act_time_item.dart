import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_status_labels.dart';
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/list/act_list_group.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/features/targets/target.dart';

class TotalActTimeListItem extends ConsumerWidget {
  final List<SavedActEntityV1> _actList;
  final Mem? _mem;
  final Target? _target;
  final ActListGroup _group;

  const TotalActTimeListItem(
    this._actList,
    this._mem,
    this._target,
    this._group, {
    super.key,
  });

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
          final now = DateAndTime.now();
          final showsActions = _group.contains(now);
          final actions = showsActions
              ? _actions(ref, memId, latestAct)
              : (leading: null, trailing: null);
          // 経過は今日の日グループだけ。週や月の途中でも今の状態は出さない
          final showsElapsed = _group.unit == Period.aDay && showsActions;
          final target = _target;
          final amount = _dayAmount(ref, memId, target);

          return ListTile(
            leading: actions.leading,
            title: _title(
              showsElapsed ? latestAct : null,
              amount,
            ),
            subtitle: _mem == null ? null : Text(_mem.name),
            trailing: actions.trailing,
            onTap: () => showMemDetailPage(context, ref, memId),
          );
        },
        {
          '_actList': _actList,
          '_mem': _mem,
          '_group': _group,
        },
      );

  DayActAmount? _dayAmount(WidgetRef ref, int memId, Target? target) {
    if (_group.unit != Period.aDay || !DayTargetLabel.shows(target)) {
      return null;
    }
    return ref.watch(viewedDayActAmountProvider(memId, _group.start)).value;
  }

  Widget _title(Act? statusAct, DayActAmount? amount) {
    final recorded = _actList.fold<Duration>(
      Duration.zero,
      (sum, act) => sum + (act.value.period?.duration ?? Duration.zero),
    );
    final target = _target;
    final progress = _progress(amount, recorded, target);
    final range = _actListRange(_actList.map((act) => act.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ActStatusLabels(
          statusAct,
          target,
          progress,
          time: _groupDuration(recorded, progress, target),
          centerTime: false,
        ),
        if (range != null)
          DateAndTimePeriodTexts(
            range,
            showDate: _group.unit != Period.aDay,
          ),
      ],
    );
  }

  // 日の進捗は Mem 一覧と同じ今日の集計。それ以外は、そのグループの Act から作る
  DayActAmount? _progress(
    DayActAmount? dayAmount,
    Duration recorded,
    Target? target,
  ) {
    if (_group.unit == Period.aDay) {
      return dayAmount;
    }
    if (!DayTargetLabel.shows(target)) {
      return null;
    }
    return DayActAmount(_actList.length, recorded);
  }

  // 時間目標がグループ合計を進捗に出すときは、合計時間を重ねて出さない
  Widget? _groupDuration(
    Duration recorded,
    DayActAmount? progress,
    Target? target,
  ) {
    if (_group.unit != Period.aDay &&
        progress != null &&
        target != null &&
        target.targetUnit == TargetUnit.time) {
      return null;
    }
    return Text(recorded.formatHHmm());
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
