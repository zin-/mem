import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/repositories/mem_item_entity.dart';

class MemItemRepository
    extends DatabaseTupleRepository<MemItemEntity, SavedMemItemEntity> {
  MemItemRepository() : super(databaseDefinition, defTableMemItems);

  @override
  SavedMemItemEntity pack(Map<String, dynamic> map) =>
      SavedMemItemEntity.fromMap(map);

  @override
  Future<List<SavedMemItemEntity>> ship({
    int? memId,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () => super.ship(
          condition: And(
            [
              if (memId != null) Equals(defFkMemItemsMemId, memId),
              if (condition != null) condition,
            ],
          ),
          groupBy: groupBy,
          orderBy: orderBy,
          offset: offset,
          limit: limit,
        ),
        {
          'memId': memId,
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  Future<Iterable<SavedMemItemEntity>> archiveBy({
    int? memId,
    DateTime? archivedAt,
  }) =>
      v(
        () async => Future.wait(
          await ship(
            condition: And(
              [
                if (memId != null) Equals(defFkMemItemsMemId, memId),
              ],
            ),
          ).then(
            (v) => v.map(
              (e) => archive(e, archivedAt: archivedAt),
            ),
          ),
        ),
        {
          'memId': memId,
          'archivedAt': archivedAt,
        },
      );

  Future<Iterable<SavedMemItemEntity>> unarchiveBy({
    int? memId,
    DateTime? updatedAt,
  }) =>
      v(
        () async => Future.wait(
          await ship(
            condition: And(
              [
                if (memId != null) Equals(defFkMemItemsMemId, memId),
              ],
            ),
          ).then(
            (v) => v.map(
              (e) => unarchive(e, updatedAt: updatedAt),
            ),
          ),
        ),
        {
          'memId': memId,
          'updatedAt': updatedAt,
        },
      );

  @override
  Future<List<SavedMemItemEntity>> waste({
    int? memId,
    Condition? condition,
  }) =>
      v(
        () => super.waste(
          condition: And(
            [
              if (memId != null) Equals(defPkId, memId),
              if (condition != null) condition,
            ],
          ),
        ),
        {
          'memId': memId,
          'condition': condition,
        },
      );
}
