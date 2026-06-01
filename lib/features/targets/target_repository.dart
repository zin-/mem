import 'package:mem/databases/definition.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/singleton.dart';

// @Deprecated('TargetRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class TargetRepository
    extends DatabaseTupleRepository<Target, int, TargetEntity> {
  TargetRepository._() : super(databaseDefinition, defTableTargets);

  Future<List<TargetEntity>> shipByMemIds(Iterable<int> memIds) => v(
        () async {
          if (memIds.isEmpty) return [];
          final db = DriftDatabaseAccessor().driftDatabase;
          final rows = await (db.select(db.targets)
                ..where((t) => t.memId.isIn(memIds)))
              .get();
          return rows.map(TargetEntity.fromTuple).toList();
        },
        {'memIds': memIds},
      );

  Future<List<TargetEntity>> shipByMemId(int memId) => v(
        () async {
          final db = DriftDatabaseAccessor().driftDatabase;
          final rows = await (db.select(db.targets)
                ..where((t) => t.memId.equals(memId)))
              .get();
          return rows.map(TargetEntity.fromTuple).toList();
        },
        {'memId': memId},
      );

  factory TargetRepository({TargetRepository? mock}) {
    if (mock != null) {
      Singleton.override<TargetRepository>(mock);
      return mock;
    }
    return Singleton.of(() => TargetRepository._());
  }
}
