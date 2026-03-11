import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';

// @Deprecated('MemItemRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class MemItemRepository
    extends DatabaseTupleRepository<MemItem, int, MemItemEntity> {
  @override
  MemItemEntity packV2(dynamic tuple) => MemItemEntity(
        tuple.memId,
        MemItemType.values.byName(tuple.type),
        tuple.value,
        tuple.id,
        tuple.createdAt,
        tuple.updatedAt,
        tuple.archivedAt,
      );

  @override
  Future<List<MemItemEntity>> shipV2({
    int? memId,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
    loadChildren = false,
  }) async =>
      await super.shipV2(
        condition: And(
          [
            if (memId != null) Equals(defFkMemItemsMemId, memId),
            if (condition != null) condition,
          ],
        ),
        loadChildren: loadChildren,
      );

  Future<Iterable<MemItemEntity>> archiveBy({
    int? memId,
    DateTime? archivedAt,
  }) =>
      v(
        () async {
          final time = archivedAt ?? DateTime.now();

          return await Future.wait(
            await shipV2(
              memId: memId,
            ).then(
              (v) => v.map(
                (e) => super.replaceV2(MemItemEntity(
                  e.memId,
                  e.type,
                  e.value,
                  e.id,
                  e.createdAt,
                  e.updatedAt,
                  time,
                )),
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
            await shipV2(
              memId: memId,
            ).then(
              (v) => v.map(
                (e) => super.replaceV2(MemItemEntity(
                  e.memId,
                  e.type,
                  e.value,
                  e.id,
                  e.createdAt,
                  time,
                  null,
                )),
              ),
            ),
          );
        },
        {
          'memId': memId,
          'updatedAt': updatedAt,
        },
      );

  static MemItemRepository? _instance;
  factory MemItemRepository({MemItemRepository? mock}) =>
      _instance ??= mock ?? MemItemRepository._();
  MemItemRepository._() : super(databaseDefinition, defTableMemItems);
}
