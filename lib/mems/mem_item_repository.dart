import 'package:mem/core/mem_item.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/database_tuple_repository.dart';
import 'package:mem/repositories/conditions/conditions.dart';

class MemItemRepository
    extends DatabaseTupleRepository<MemItemV2, SavedMemItemV2<int>, int> {
  Future<Iterable<SavedMemItemV2<int>>> shipByMemId(int memId) => v(
        () => super.ship(Equals(defFkMemItemsMemId.name, memId)),
        {'memId': memId},
      );

  Future<Iterable<SavedMemItemV2<int>>> archiveByMemId(int memId) => v(
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.archive(e))),
        {'memId': memId},
      );

  Future<Iterable<SavedMemItemV2<int>>> unarchiveByMemId(int memId) => v(
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.unarchive(e))),
        {'memId': memId},
      );

  Future<Iterable<SavedMemItemV2<int>>> wasteByMemId(int memId) => v(
        () async => await super.waste(Equals(defFkMemItemsMemId.name, memId)),
        {'memId': memId},
      );

  @override
  SavedMemItemV2<int> pack(Map<String, dynamic> tuple) => SavedMemItemV2(
        tuple[defFkMemItemsMemId.name],
        MemItemType.values.firstWhere(
          (v) => v.name == tuple[defColMemItemsType.name],
        ),
        tuple[defColMemItemsValue.name],
      )..pack(tuple);

  @override
  Map<String, dynamic> unpack(MemItemV2 entity) {
    final map = {
      defFkMemItemsMemId.name: entity.memId,
      defColMemItemsType.name: entity.type.name,
      defColMemItemsValue.name: entity.value,
    };

    if (entity is SavedMemItemV2) {
      map.addAll(entity.unpack());
    }

    return map;
  }

  MemItemRepository._() : super(defTableMemItems);

  static MemItemRepository? _instance;

  factory MemItemRepository() => _instance ??= MemItemRepository._();
}
