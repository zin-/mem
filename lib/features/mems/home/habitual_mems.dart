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
    DateTime? earliest;
    for (final act in acts) {
      final start = act.period?.start;
      if (start == null) continue;
      if (earliest == null || start.isBefore(earliest)) earliest = start;
    }
    final windows = earliest == null
        ? const <DateAndTimePeriod>[]
        : _dayWindows(now, earliest);

    bool hits(DateAndTimePeriod? period) {
      if (period == null || period.start == null || period.end == null) {
        return false;
      }
      for (final window in windows) {
        if (period.overlaps(window)) return true;
      }
      return false;
    }

    final actsByMemId = <int, List<Act>>{};
    for (final act in acts) {
      if (!hits(act.period)) continue;
      (actsByMemId[act.memId] ??= []).add(act);
    }

    final ranked = <({MemEntity mem, Duration time, int score})>[];
    for (final mem in mems) {
      final matched = actsByMemId[mem.id];
      if (matched == null) continue;
      ranked.add((
        mem: mem,
        time: _totalTime(matched),
        score: _points(matched, now),
      ));
    }

    ranked.sort((a, b) {
      final byTime = b.time.compareTo(a.time);
      if (byTime != 0) return byTime;
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.mem.id.compareTo(b.mem.id);
    });

    return HabitualMems._(ranked.map((entry) => entry.mem).toList());
  }

  static List<DateAndTimePeriod> _dayWindows(DateTime now, DateTime earliest) {
    final windows = <DateAndTimePeriod>[];
    final last = DateTime(now.year, now.month, now.day);
    for (var day = DateTime(earliest.year, earliest.month, earliest.day - 1);
        !day.isAfter(last);
        day = DateTime(day.year, day.month, day.day + 1)) {
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
      windows.add(
        DateAndTimePeriod(
          start: _time(center.subtract(timeRadius)),
          end: _time(center.add(timeRadius)),
        ),
      );
    }
    return windows;
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

  static Duration _totalTime(Iterable<Act> acts) {
    var total = Duration.zero;
    for (final act in acts) {
      total += act.period?.duration ?? Duration.zero;
    }
    return total;
  }

  static int _points(Iterable<Act> acts, DateTime now) {
    var points = 0;
    for (final act in acts) {
      points += 1;
      if (act.period?.start?.weekday == now.weekday) {
        points += 1;
      }
    }
    return points;
  }
}

final habitualMemsProvider = FutureProvider.autoDispose<List<MemEntity>>((ref) {
  ref.listen(loadMemListProvider, (_, __) {});

  final mems = ref.watch(memEntitiesProvider);
  final now = DateTime.now();
  return v(
    () async {
      final acts = await ActQueryService().fetchFinishedStartedAround(
        now: now,
        timeRadius: HabitualMems.timeRadius,
        lookback: HabitualMems.lookback,
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
