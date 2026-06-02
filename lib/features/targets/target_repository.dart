import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart'
    show
        TargetEntity,
        convertIntoTargetsInsertable,
        convertIntoTargetsUpdateable;
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

// @Deprecated('TargetRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class TargetRepository extends DriftRepository {
  Future<TargetEntity> receive(Target domain) => v(
        () async {
          final inserted = await driftDb.into(driftDb.targets).insertReturning(
                convertIntoTargetsInsertable(domain),
              );
          return TargetEntity.fromTuple(inserted);
        },
        {'domain': domain},
      );

  Future<TargetEntity> replace(TargetEntity entity) => v(
        () async {
          final updated = await (driftDb.update(driftDb.targets)
                ..where((t) => t.id.equals(entity.id)))
              .writeReturning(convertIntoTargetsUpdateable(entity));
          return TargetEntity.fromTuple(updated.single);
        },
        {'entity': entity},
      );

  Future<List<TargetEntity>> waste({int? memId}) => v(
        () async {
          var query = driftDb.delete(driftDb.targets);
          if (memId != null) {
            query = query..where((t) => t.memId.equals(memId));
          }
          final deleted = await query.goAndReturn();
          return deleted.map(TargetEntity.fromTuple).toList();
        },
        {'memId': memId},
      );

  Future<List<TargetEntity>> shipByMemIds(Iterable<int> memIds) => v(
        () async {
          if (memIds.isEmpty) return [];
          final rows = await (driftDb.select(driftDb.targets)
                ..where((t) => t.memId.isIn(memIds)))
              .get();
          return rows.map(TargetEntity.fromTuple).toList();
        },
        {'memIds': memIds},
      );

  Future<List<TargetEntity>> shipByMemId(int memId) => v(
        () async {
          final rows = await (driftDb.select(driftDb.targets)
                ..where((t) => t.memId.equals(memId)))
              .get();
          return rows.map(TargetEntity.fromTuple).toList();
        },
        {'memId': memId},
      );

  TargetRepository._();

  factory TargetRepository({TargetRepository? mock}) {
    if (mock != null) {
      Singleton.override<TargetRepository>(mock);
      return mock;
    }
    return Singleton.of(() => TargetRepository._());
  }
}
