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
