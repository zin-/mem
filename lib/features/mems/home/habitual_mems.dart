import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/mem_entity.dart';

class HabitualMems {
  static const timeRadius = Duration(hours: 1);
  static const lookback = Duration(days: 28);
  static const minCount = 2;

  final List<MemEntity> mems;

  HabitualMems._(this.mems);

  static HabitualMems of(
    Iterable<Act> acts,
    Iterable<MemEntity> mems, {
    required DateTime now,
  }) {
    final actsByMemId = <int, List<Act>>{};
    for (final act in acts) {
      (actsByMemId[act.memId] ??= []).add(act);
    }

    final ranked = <({MemEntity mem, int rank})>[];
    for (final mem in mems) {
      if (mem.isArchived || mem.doneAt != null) {
        continue;
      }
      final rank = _rank(actsByMemId[mem.id] ?? const [], now);
      if (rank < minCount) {
        continue;
      }
      ranked.add((mem: mem, rank: rank));
    }

    ranked.sort((a, b) {
      final compared = b.rank.compareTo(a.rank);
      if (compared != 0) {
        return compared;
      }
      return a.mem.id.compareTo(b.mem.id);
    });

    return HabitualMems._(ranked.map((entry) => entry.mem).toList());
  }

  static int _rank(Iterable<Act> acts, DateTime now) =>
      acts.where((act) => act.period?.start?.weekday == now.weekday).length;
}
