import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/i/_database_tuple_repository_v2.dart';
import 'package:mem/repositories/i/conditions.dart';

import 'mem_item_entity_v2.dart';

class MemItemRepository
    extends DatabaseTupleRepository<MemItemEntity, MemItem> {
  Future<Iterable<MemItem>> shipByMemId(MemId memId) => v(
        () => super.ship(Equals(memIdFkDef.name, memId)),
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
        () async => await super.waste(Equals(memIdFkDef.name, memId)),
        {'memId': memId},
      );

  @override
  UnpackedPayload unpack(MemItem payload) => {
        memIdFkDef.name: payload.memId,
        memItemTypeColDef.name: payload.type.name,
        memItemValueColDef.name: payload.value,
        idPKDef.name: payload.id,
        createdAtColDef.name: payload.createdAt,
        updatedAtColDef.name: payload.updatedAt,
        archivedAtColDef.name: payload.archivedAt,
      };

  @override
  MemItem pack(UnpackedPayload unpackedPayload) {
    final memItemEntity = MemItemEntity(
      memId: unpackedPayload[memIdFkDef.name],
      type: MemItemType.values.firstWhere((v) {
        return v.name == unpackedPayload[memItemTypeColDef.name];
      }),
      value: unpackedPayload[memItemValueColDef.name],
      id: unpackedPayload[idPKDef.name],
      createdAt: unpackedPayload[createdAtColDef.name],
      updatedAt: unpackedPayload[updatedAtColDef.name],
      archivedAt: unpackedPayload[archivedAtColDef.name],
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

  MemItemRepository._(super.table);

  static MemItemRepository? _instance;

  factory MemItemRepository([Table? table]) =>
      _instance ??= MemItemRepository._(table!);

  static resetWith(MemItemRepository? instance) => _instance = instance;
}
