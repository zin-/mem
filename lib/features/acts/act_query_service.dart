import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
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

  ActQueryService._();

  factory ActQueryService() => Singleton.of(() => ActQueryService._());
}
