import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/mems/list/list_period_count.dart';

// list_period_count から ActQueryService を import すると循環する
extension ListPeriodWindowCounts on ListPeriodWindows {
  Future<List<ActEntity>> fetchActs() async {
    final acts = <ActEntity>[];
    for (final group in groups) {
      acts.addAll(
        await ActQueryService().fetchByMemIdsAndPeriod(
          group.memIds,
          group.period,
        ),
      );
    }
    return acts;
  }

  Future<Map<int, int>> counts() async => countsOf([
        for (final act in await fetchActs())
          if (act.memId != null) act.toDomain(),
      ]);
}
