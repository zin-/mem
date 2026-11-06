import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_status_labels.dart';
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';

class TotalActTimeListItem extends ConsumerWidget {
  final List<SavedActEntityV1> _actList;
  final Mem? _mem;
  final Target? _target;
  final DateTime _groupDate;
  final bool _isDateView;

  const TotalActTimeListItem(
    this._actList,
    this._mem,
    this._target,
    this._groupDate,
    this._isDateView, {
    super.key,
  });

  bool _isCurrentPeriod(DateAndTime now, TimeOfDay startOfDay) {
    if (_isDateView) {
      return now.isSameLogicalDay(_groupDate, startOfDay);
    }
    return now.isSameLogicalMonth(_groupDate, startOfDay);
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
          final startOfDay = ref.watch(preferenceProvider(startOfDayKey));
          final now = DateAndTime.now();
          final actions = _isCurrentPeriod(now, startOfDay)
              ? _actions(ref, memId, latestAct)
              : (leading: null, trailing: null);
          final isToday =
              _isDateView && now.isSameLogicalDay(_groupDate, startOfDay);
          final target = _target;
          final amount = _dayAmount(ref, memId, target);

          return ListTile(
            leading: actions.leading,
            title: _title(
              // 今日の日表示だけ。月表示と別の日には今の状態を出さない
              isToday ? latestAct : null,
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
          '_groupDate': _groupDate,
          '_isDateView': _isDateView,
        },
      );

  DayActAmount? _dayAmount(WidgetRef ref, int memId, Target? target) {
    if (!_isDateView || !DayTargetLabel.shows(target)) {
      return null;
    }
    final day = DateTime(_groupDate.year, _groupDate.month, _groupDate.day);
    return ref.watch(viewedDayActAmountProvider(memId, day)).value;
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
            showDate: !_isDateView,
          ),
      ],
    );
  }

  // 日表示の進捗は Mem 一覧と同じ今日の集計。月表示だけ、その月の Act から作る
  DayActAmount? _progress(
    DayActAmount? dayAmount,
    Duration recorded,
    Target? target,
  ) {
    if (_isDateView) {
      return dayAmount;
    }
    if (!DayTargetLabel.shows(target)) {
      return null;
    }
    return DayActAmount(_actList.length, recorded);
  }

  // 時間目標が同じ合計を出す月表示では、合計時間を重ねて出さない
  Widget? _groupDuration(
    Duration recorded,
    DayActAmount? progress,
    Target? target,
  ) {
    if (!_isDateView &&
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
