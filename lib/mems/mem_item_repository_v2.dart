import 'package:mem/core/errors.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/database/database.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_item_entity_v2.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/i/_database_tuple_repository_v2.dart';
import 'package:mem/repositories/i/conditions.dart';
import 'package:mem/repositories/mem_item_repository.dart';

class MemItemRepositoryV2
    extends DatabaseTupleRepositoryV2<MemItemEntityV2, MemItem> {
  Future<Iterable<MemItem>> shipByMemId(MemId memId) => v(
        {'memId': memId},
        () => super.ship(Equals(memIdColumnName, memId)),
      );

  Future<Iterable<MemItem>> archiveByMemId(MemId memId) => v(
        {'memId': memId},
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.archive(e))),
      );

  Future<Iterable<MemItem>> unarchiveByMemId(MemId memId) => v(
        {'memId': memId},
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.unarchive(e))),
      );

  Future<Iterable<MemItem>> wasteByMemId(MemId memId) => v(
        {'memId': memId},
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.wasteById(e.id))),
      );

  @override
  UnpackedPayload unpack(MemItem payload) => {
        memIdColumnName: payload.memId,
        memItemTypeColumnName: payload.type,
        memItemValueColumnName: payload.value,
        idColumnName: payload.id,
        createdAtColumnName: payload.createdAt,
        updatedAtColumnName: payload.updatedAt,
        archivedAtColumnName: payload.archivedAt,
      };

  @override
  MemItem pack(UnpackedPayload unpackedPayload) {
    final memItemEntity = MemItemEntityV2(
      memId: unpackedPayload[memIdColumnName],
      type: unpackedPayload[memItemTypeColumnName],
      value: unpackedPayload[memItemValueColumnName],
      id: unpackedPayload[idColumnName],
      createdAt: unpackedPayload[createdAtColumnName],
      updatedAt: unpackedPayload[updatedAtColumnName],
      archivedAt: unpackedPayload[archivedAtColumnName],
    );

    return MemItem(
      memId: memItemEntity.memId,
      type: memItemEntity.type,
      value: memItemEntity.value,
      id: memItemEntity.value,
      createdAt: memItemEntity.createdAt,
      updatedAt: memItemEntity.updatedAt,
      archivedAt: memItemEntity.archivedAt,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  MemItemRepositoryV2._(super.table);

  factory MemItemRepositoryV2([Table? table]) {
    var tmp = _instance;

    if (tmp == null) {
      if (table == null) {
        throw InitializationError();
      }
      _instance = tmp = MemItemRepositoryV2._(table);
    }

    return tmp;
  }

  static MemItemRepositoryV2? _instance;

  static resetWith(MemItemRepositoryV2? instance) => _instance = instance;
}
