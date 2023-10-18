import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/database_tuple_repository.dart';
import 'package:mem/repositories/conditions/conditions.dart';

import 'mem_item_entity.dart';

class MemItemRepository
    extends DatabaseTupleRepositoryV2<MemItemEntity, MemItem> {
  Future<Iterable<MemItem>> shipByMemId(MemId memId) => v(
        () => super.ship(Equals(defFkMemItemsMemId.name, memId)),
        {'memId': memId},
      );

  Future<Iterable<MemItem>> archiveByMemId(MemId memId) => v(
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.archive(e))),
        {'memId': memId},
      );

  Future<Iterable<MemItem>> unarchiveByMemId(MemId memId) => v(
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.unarchive(e))),
        {'memId': memId},
      );

  Future<Iterable<MemItem>> wasteByMemId(MemId memId) => v(
        () async => await super.waste(Equals(defFkMemItemsMemId.name, memId)),
        {'memId': memId},
      );

  @override
  Map<String, dynamic> unpack(MemItem payload) => {
        defFkMemItemsMemId.name: payload.memId,
        defColMemItemsType.name: payload.type.name,
        defColMemItemsValue.name: payload.value,
        defPkId.name: payload.id,
        defColCreatedAt.name: payload.createdAt,
        defColUpdatedAt.name: payload.updatedAt,
        defColArchivedAt.name: payload.archivedAt,
      };

  @override
  MemItem pack(Map<String, dynamic> unpackedPayload) {
    final memItemEntity = MemItemEntity(
      memId: unpackedPayload[defFkMemItemsMemId.name],
      type: MemItemType.values.firstWhere((v) {
        return v.name == unpackedPayload[defColMemItemsType.name];
      }),
      value: unpackedPayload[defColMemItemsValue.name],
      id: unpackedPayload[defPkId.name],
      createdAt: unpackedPayload[defColCreatedAt.name],
      updatedAt: unpackedPayload[defColUpdatedAt.name],
      archivedAt: unpackedPayload[defColArchivedAt.name],
    );

    return MemItem(
      memId: memItemEntity.memId,
      type: memItemEntity.type,
      value: memItemEntity.value,
      id: memItemEntity.id,
      createdAt: memItemEntity.createdAt,
      updatedAt: memItemEntity.updatedAt,
      archivedAt: memItemEntity.archivedAt,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  MemItemRepository._() : super(defTableMemItems);

  static MemItemRepository? _instance;

  factory MemItemRepository() => _instance ??= MemItemRepository._();

  static resetWith(MemItemRepository? instance) => _instance = instance;
}
