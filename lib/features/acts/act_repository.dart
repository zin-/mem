import 'package:drift/drift.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart'
    show ActEntity, convertIntoActsInsertable, convertIntoActsUpdateable;
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

// @Deprecated('ActRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class ActRepository extends DriftRepository {
  Future<ActEntity> receive(Act domain) => v(
        () async {
          final inserted = await driftDb.into(driftDb.acts).insertReturning(
                convertIntoActsInsertable(domain, createdAt: DateTime.now()),
              );
          return ActEntity.fromTuple(inserted);
        },
        {'domain': domain},
      );

  Future<ActEntity> replace(ActEntity entity) => v(
        () async {
          final updated = await (driftDb.update(driftDb.acts)
                ..where((t) => t.id.equals(entity.id)))
              .writeReturning(convertIntoActsUpdateable(entity));
          return ActEntity.fromTuple(updated.single);
        },
        {'entity': entity},
      );

  Future<List<ActEntity>> waste({int? id}) => v(
        () async {
          var query = driftDb.delete(driftDb.acts);
          if (id != null) {
            query = query..where((t) => t.id.equals(id));
          }
          final deleted = await query.goAndReturn();
          return deleted.map(ActEntity.fromTuple).toList();
        },
        {
          'id': id,
        },
      );

  Future<List<ActEntity>> wastePausedAct(int memId) => v(
        () async {
          final deleted = await (driftDb.delete(driftDb.acts)
                ..where(
                  (t) => t.memId.equals(memId) & t.pausedAt.isNotNull(),
                ))
              .goAndReturn();
          return deleted.map(ActEntity.fromTuple).toList();
        },
        {'memId': memId},
      );

  ActRepository._();

  factory ActRepository({ActRepository? mock}) {
    if (mock != null) {
      Singleton.override<ActRepository>(mock);
      return mock;
    }
    return Singleton.of(() => ActRepository._());
  }
}
