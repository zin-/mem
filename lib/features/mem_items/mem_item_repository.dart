import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';

// @Deprecated('MemItemRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class MemItemRepository extends DatabaseTupleRepository<MemItemEntity,
    SavedMemItemEntity, MemItem> {
  @override
  SavedMemItemEntity pack(Map<String, dynamic> map) => SavedMemItemEntity(map);

  @override
  Future<List<SavedMemItemEntity>> ship({
    int? memId,
    Iterable<int>? memIdsIn,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      super.ship(
        condition: And(
          [
            if (memId != null) Equals(defFkMemItemsMemId, memId),
            if (memIdsIn != null) In(defFkMemItemsMemId.name, memIdsIn),
            if (condition != null) condition,
          ],
        ),
        groupBy: groupBy,
        orderBy: orderBy,
        offset: offset,
        limit: limit,
      );

  Future<Iterable<SavedMemItemEntity>> archiveBy({
    int? memId,
    DateTime? archivedAt,
  }) =>
      v(
        () async {
          final time = archivedAt ?? DateTime.now();

          return await Future.wait(
            await ship(
              memId: memId,
            ).then(
              (v) => v.map(
                (e) => archive(e, archivedAt: time),
              ),
            ),
          );
        },
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
        () async {
          final time = updatedAt ?? DateTime.now();

          return await Future.wait(
            await ship(
              memId: memId,
            ).then(
              (v) => v.map(
                (e) => unarchive(e, updatedAt: time),
              ),
            ),
          );
        },
        {
          'memId': memId,
          'updatedAt': updatedAt,
        },
      );

  @override
  Future<List<SavedMemItemEntity>> waste({
    Condition? condition,
  }) =>
      super.waste(
        condition: And(
          [
            if (condition != null) condition, // coverage:ignore-line
          ],
        ),
      );

  static MemItemRepository? _instance;
  factory MemItemRepository({MemItemRepository? mock}) =>
      _instance ??= mock ?? MemItemRepository._();
  MemItemRepository._() : super(databaseDefinition, defTableMemItems);
}
