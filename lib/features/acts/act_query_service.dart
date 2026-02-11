import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_service.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/extra_column.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/singleton.dart';

class ActQueryService {
  static final _driftAccessor = DriftDatabaseAccessor();

  Future<int> countByMemIdIs(MemId memId) => v(
        () => _driftAccessor.count(
          defTableActs,
          condition: Equals(defFkActsMemId, memId),
        ),
        {
          'memId': memId,
        },
      );

  Future<int> activeCount() => v(
        () => _driftAccessor.count(
          defTableActs,
          condition: And(
            [
              IsNotNull(defColActsStart.name),
              IsNull(defColActsEnd.name),
            ],
          ),
        ),
      );

  Future<List<ActEntity>> fetchLatestAndPausedByMemIds(Iterable<int>? memIds) =>
      v(
        () async => await _driftAccessor
            .select(
              defTableActs,
              condition: And(
                [
                  if (memIds != null) In(defFkActsMemId.name, memIds),
                  IsNotNull(defColActsPausedAt.name),
                ],
              ),
              groupBy: GroupBy(
                [defFkActsMemId],
                extraColumns: [Max(defColActsStart)],
              ),
            )
            .then(
              (v) => v.map((e) {
                return ActEntity.fromTuple(e);
              }).toList(),
            ),
        {'memIds': memIds},
      );

  Future<ActEntity?> fetchLatestByMemIds(int memId) => v(
        () {
          return _driftAccessor
              .select(
            defTableActs,
            condition: Equals(defFkActsMemId, memId),
            orderBy: [Descending(defColActsStart)],
            limit: 1,
          )
              .then((v) {
            final act = v.singleOrNull;

            if (act == null) {
              return null;
            } else {
              return ActEntity.fromTuple(act);
            }
          });
        },
        {'memId': memId},
      );

  Future<ListWithTotalCount<ActEntity>> fetchPaging(
    int? memId,
    int offset,
    int limit,
  ) =>
      v(
        () async {
          return ListWithTotalCount(
            await _driftAccessor
                .select(
                  defTableActs,
                  condition:
                      memId == null ? null : Equals(defFkActsMemId, memId),
                  orderBy: [Descending(defColActsStart)],
                  offset: offset,
                  limit: limit,
                )
                .then((v) => v.map((e) {
                      return ActEntity.fromTuple(e);
                    }).toList()),
            await countByMemIdIs(memId),
          );
        },
        {
          'memId': memId,
          'offset': offset,
          'limit': limit,
        },
      );

  ActQueryService._();

  factory ActQueryService() => Singleton.of(() => ActQueryService._());
}
