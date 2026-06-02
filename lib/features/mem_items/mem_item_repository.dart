import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart'
    show MemItemEntity, convertIntoMemItemsInsertable, convertIntoMemItemsUpdateable;
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

// @Deprecated('MemItemRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class MemItemRepository extends DriftRepository {
  Future<List<MemItemEntity>> ship({int? memId}) => v(
        () async {
          var query = driftDb.select(driftDb.memItems);
          if (memId != null) {
            query = query..where((t) => t.memId.equals(memId));
          }
          final rows = await query.get();
          return rows.map(MemItemEntity.fromTuple).toList();
        },
        {'memId': memId},
      );

  Future<MemItemEntity> receive(MemItem domain) => v(
        () async {
          final inserted = await driftDb.into(driftDb.memItems).insertReturning(
                convertIntoMemItemsInsertable(domain, DateTime.now()),
              );
          return MemItemEntity.fromTuple(inserted);
        },
        {'domain': domain},
      );

  Future<MemItemEntity> replace(MemItemEntity entity) => v(
        () async {
          final updated = await (driftDb.update(driftDb.memItems)
                ..where((t) => t.id.equals(entity.id)))
              .writeReturning(convertIntoMemItemsUpdateable(entity));
          return MemItemEntity.fromTuple(updated.single);
        },
        {'entity': entity},
      );

  Future<Iterable<MemItemEntity>> archiveBy({
    int? memId,
    DateTime? archivedAt,
  }) =>
      v(
        () async {
          final time = archivedAt ?? DateTime.now();

          return await Future.wait(
            (await ship(memId: memId)).map(
              (e) => replace(
                MemItemEntity(
                  e.memId,
                  e.type,
                  e.value,
                  e.id,
                  e.createdAt,
                  e.updatedAt,
                  time,
                ),
              ),
            ),
          );
        },
        {
          'memId': memId,
          'archivedAt': archivedAt,
        },
      );

  Future<Iterable<MemItemEntity>> unarchiveBy({
    int? memId,
    DateTime? updatedAt,
  }) =>
      v(
        () async {
          final time = updatedAt ?? DateTime.now();

          return await Future.wait(
            (await ship(memId: memId)).map(
              (e) => replace(
                MemItemEntity(
                  e.memId,
                  e.type,
                  e.value,
                  e.id,
                  e.createdAt,
                  time,
                  null,
                ),
              ),
            ),
          );
        },
        {
          'memId': memId,
          'updatedAt': updatedAt,
        },
      );

  MemItemRepository._();

  factory MemItemRepository({MemItemRepository? mock}) {
    if (mock != null) {
      Singleton.override<MemItemRepository>(mock);
      return mock;
    }
    return Singleton.of(() => MemItemRepository._());
  }
}
