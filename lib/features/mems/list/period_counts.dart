import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/mems/list/list_period_count.dart';

// list_period_count から ActQueryService を import すると循環する
extension ListPeriodWindowCounts on ListPeriodWindows {
  Future<Map<int, int>> counts() async {
    final counts = <int, int>{};
    for (final group in groups) {
      for (final memId in group.memIds) {
        counts[memId] = 0;
      }
      final acts = await ActQueryService().fetchByMemIdsAndPeriod(
        group.memIds,
        group.period,
      );
      for (final act in acts) {
        final memId = act.memId;
        if (memId == null) continue;
        final count = counts[memId];
        if (count == null) continue;
        counts[memId] = count + 1;
      }
    }
    return counts;
  }
}
