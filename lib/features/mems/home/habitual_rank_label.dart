import 'package:material_ui/material_ui.dart';
import 'package:mem/framework/date_and_time/duration_ext.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/habitual_mems.dart';

class HabitualRankLabel extends StatelessWidget {
  final HabitualRank _rank;

  const HabitualRankLabel(this._rank, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () => Wrap(
          children: [
            _HabitualRankChunk(
              _rank.sameWeekdayTime,
              _rank.sameWeekdayCount,
            ),
            const Text(' / '),
            _HabitualRankChunk(
              _rank.totalTime,
              _rank.totalCount,
            ),
          ],
        ),
        {'_rank': _rank},
      );
}

class _HabitualRankChunk extends StatelessWidget {
  final Duration _time;
  final int _count;

  const _HabitualRankChunk(this._time, this._count);

  @override
  Widget build(BuildContext context) => v(
        () => Text('${_time.formatElapsedTime()}, $_count'),
        {
          '_time': _time,
          '_count': _count,
        },
      );
}
