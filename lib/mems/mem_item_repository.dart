import 'package:mem/core/mem_item.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/mems/mem_item.dart';

class MemItemRepository
    extends DatabaseTupleRepository<MemItem, SavedMemItem, int> {
  Future<List<SavedMemItem>> shipByMemId(int memId) => v(
        () => super.ship(Equals(defFkMemItemsMemId.name, memId)),
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
        () async => await super.waste(Equals(defFkMemItemsMemId.name, memId)),
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
