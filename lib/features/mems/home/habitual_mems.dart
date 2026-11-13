import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

class HabitualMems {
  // TODO settingsから持ってきたい https://github.com/zin-/mem/issues/752
  static const timeRadius = Duration(hours: 1);
  static const lookback = Duration(days: 28);

  final List<MemEntity> mems;

  HabitualMems._(this.mems);

  static HabitualMems of(
    Iterable<Act> acts,
    Iterable<MemEntity> mems, {
    required DateTime now,
  }) {
    final ordered = acts.toList()
      ..sort((a, b) {
        final aEnd = a.period?.end;
        final bEnd = b.period?.end;
        if (aEnd == null) return 1;
        if (bEnd == null) return -1;
        return bEnd.compareTo(aEnd);
      });

    var day = DateTime(now.year, now.month, now.day);
    final windows = <DateAndTimePeriod>[_window(now, day)];
    final actsByMemId = <int, List<Act>>{};
    for (final act in ordered) {
      final period = act.period;
      final end = period?.end;
      if (period == null || period.start == null || end == null) continue;
      while (end.isBefore(windows.last.start!)) {
        day = DateTime(day.year, day.month, day.day - 1);
        windows.add(_window(now, day));
        if (windows.length == 3) windows.removeAt(0);
      }
      for (final window in windows) {
        if (!period.overlaps(window)) continue;
        (actsByMemId[act.memId] ??= []).add(act);
        break;
      }
    }

    final ranked = <({MemEntity mem, _HabitualRank rank})>[];
    for (final mem in mems) {
      final matched = actsByMemId[mem.id];
      if (matched == null) continue;
      ranked.add((
        mem: mem,
        rank: _HabitualRank.of(matched, now: now),
      ));
    }

    ranked.sort((a, b) {
      final byRank = b.rank.compareTo(a.rank);
      if (byRank != 0) return byRank;
      return a.mem.id.compareTo(b.mem.id);
    });

    return HabitualMems._(ranked.map((entry) => entry.mem).toList());
  }

  static DateAndTimePeriod _window(DateTime now, DateTime day) {
    final center = DateTime(
      day.year,
      day.month,
      day.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
    return DateAndTimePeriod(
      start: _time(center.subtract(timeRadius)),
      end: _time(center.add(timeRadius)),
    );
  }

  static DateAndTime _time(DateTime value) => DateAndTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
        value.millisecond,
        value.microsecond,
      );
}

class _HabitualRank {
  static const _halfDifference = 0.5;

  final Duration sameWeekdayTime;
  final int sameWeekdayCount;
  final Duration totalTime;
  final int totalCount;

  _HabitualRank._(
    this.sameWeekdayTime,
    this.sameWeekdayCount,
    this.totalTime,
    this.totalCount,
  );

  static _HabitualRank of(
    Iterable<Act> acts, {
    required DateTime now,
  }) {
    var sameWeekdayTime = Duration.zero;
    var sameWeekdayCount = 0;
    var totalTime = Duration.zero;
    var totalCount = 0;
    for (final act in acts) {
      final duration = act.period?.duration ?? Duration.zero;
      totalTime += duration;
      totalCount += 1;
      if (act.period?.start?.weekday == now.weekday) {
        sameWeekdayTime += duration;
        sameWeekdayCount += 1;
      }
    }
    return _HabitualRank._(
      sameWeekdayTime,
      sameWeekdayCount,
      totalTime,
      totalCount,
    );
  }

  int compareTo(_HabitualRank other) {
    int byMagnitude(int value, int otherValue) {
      final larger = value > otherValue ? value : otherValue;
      if (larger == 0) return 0;
      final difference = (value - otherValue).abs() / larger;
      if (difference <= _halfDifference) return 0;
      return value.compareTo(otherValue);
    }

    final bySameWeekdayTime = byMagnitude(
      sameWeekdayTime.inMicroseconds,
      other.sameWeekdayTime.inMicroseconds,
    );
    if (bySameWeekdayTime != 0) return bySameWeekdayTime;

    final bySameWeekdayCount = byMagnitude(
      sameWeekdayCount,
      other.sameWeekdayCount,
    );
    if (bySameWeekdayCount != 0) return bySameWeekdayCount;

    final byTotalTime = byMagnitude(
      totalTime.inMicroseconds,
      other.totalTime.inMicroseconds,
    );
    if (byTotalTime != 0) return byTotalTime;

    return byMagnitude(totalCount, other.totalCount);
  }
}

final habitualMemsProvider = FutureProvider.autoDispose<List<MemEntity>>((ref) {
  ref.listen(loadMemListProvider, (_, __) {});

  final mems = ref.watch(memEntitiesProvider);
  final now = DateTime.now();
  return v(
    () async {
      final acts = await ActQueryService().fetchFinishedStartedAround(
        since: now.subtract(HabitualMems.lookback),
        until: now,
      );
      return HabitualMems.of(
        acts.map((act) => act.toDomain()),
        mems,
        now: now,
      ).mems;
    },
    {
      'mems': mems,
      'now': now,
    },
  );
});
