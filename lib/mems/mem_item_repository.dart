import 'package:mem/core/mem_item.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/database_tuple_repository_v1.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/mems/mem_item.dart';
import 'package:mem/repositories/mem_item_entity.dart';

class MemItemRepositoryV2
    extends DatabaseTupleRepository<MemItemEntity, SavedMemItemEntity> {
  MemItemRepositoryV2() : super(databaseDefinition, defTableMemItems);

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
}

class MemItemRepository
    extends DatabaseTupleRepositoryV1<MemItem, SavedMemItem, int> {
  Future<List<SavedMemItem>> shipByMemId(int memId) => v(
        () => super.ship(condition: Equals(defFkMemItemsMemId, memId)),
        {'memId': memId},
      );

  Future<Iterable<SavedMemItem>> archiveByMemId(int memId) => v(
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.archive(e))),
        {'memId': memId},
      );

  Future<Iterable<SavedMemItem>> unarchiveByMemId(int memId) => v(
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.unarchive(e))),
        {'memId': memId},
      );

  Future<Iterable<SavedMemItem>> wasteByMemId(int memId) => v(
        () async => await super.waste(Equals(defFkMemItemsMemId, memId)),
        {'memId': memId},
      );

  @override
  SavedMemItem pack(Map<String, dynamic> tuple) => SavedMemItem(
        tuple[defFkMemItemsMemId.name],
        MemItemType.values.firstWhere(
          (v) => v.name == tuple[defColMemItemsType.name],
        ),
        tuple[defColMemItemsValue.name],
      )..pack(tuple);

  @override
  Map<String, dynamic> unpack(MemItem entity) {
    final map = {
      defFkMemItemsMemId.name: entity.memId,
      defColMemItemsType.name: entity.type.name,
      defColMemItemsValue.name: entity.value,
    };

    if (entity is SavedMemItem) {
      map.addAll(entity.unpack());
    }

    return map;
  }

  MemItemRepository._() : super(defTableMemItems);

  static MemItemRepository? _instance;

  factory MemItemRepository() => v(
        () => _instance ??= MemItemRepository._(),
      );
}
