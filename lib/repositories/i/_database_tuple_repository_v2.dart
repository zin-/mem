import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/_repository_v2.dart';
import 'package:mem/repositories/i/types.dart';

import '_database_tuple_entity_v2.dart';
import 'conditions.dart';

typedef UnpackedPayload = Map<AttributeName, dynamic>;

abstract class DatabaseTupleRepository<E extends DatabaseTupleEntity, P>
    implements RepositoryV2<E, P> {
  final Table _table;

  DatabaseTupleRepository(this._table);

  UnpackedPayload unpack(P payload);

  P pack(UnpackedPayload unpackedPayload);

  @override
  Future<P> receive(P payload) => v(
        () async {
          final entityMap = unpack(payload);

          entityMap[createdAtColDef.name] = DateTime.now();

          final id = await _table.insert(entityMap);

          entityMap[idPKDef.name] = id;

          return pack(entityMap);
        },
        {'payload': payload},
      );

  @override
  Future<List<P>> ship([Condition? condition]) => v(
        () async => (await _table.select(
          whereString: condition?.whereString(),
          whereArgs: condition?.whereArgs(),
        ))
            .map((e) => pack(e))
            .toList(),
        {'condition': condition},
      );

  @override
  Future<P> shipById(id) => v(
        () async => pack(await _table.selectByPk(id)),
        {'id': id},
      );

  @override
  Future<P> replace(P payload) => v(
        () async {
          final entityMap = unpack(payload);

          if (entityMap[createdAtColDef.name] == null) {
            entityMap[createdAtColDef.name] = DateTime.now();
          }
          entityMap[updatedAtColDef.name] = DateTime.now();

          await _table.updateByPk(
            entityMap[idPKDef.name],
            entityMap,
          );

          return pack(entityMap);
        },
        {'payload': payload},
      );

  @override
  Future<P> archive(P payload) => v(
        () async {
          final entityMap = unpack(payload);

          entityMap[archivedAtColDef.name] = DateTime.now();

          await _table.updateByPk(
            entityMap[idPKDef.name],
            entityMap,
          );

          return pack(entityMap);
        },
        {'payload': payload},
      );

  @override
  Future<P> unarchive(P payload) => v(
        () async {
          final entityMap = unpack(payload);

          entityMap[updatedAtColDef.name] = DateTime.now();
          entityMap[archivedAtColDef.name] = null;

          await _table.updateByPk(
            entityMap[idPKDef.name],
            entityMap,
          );

          return pack(entityMap);
        },
        {'payload': payload},
      );

  @override
  Future<List<P>> waste([Condition? condition]) => v(
        () async {
          final payloads = (await _table.select(
            whereString: condition?.whereString(),
            whereArgs: condition?.whereArgs(),
          ))
              .map((e) => pack(e))
              .toList();

          final count = await _table.delete(
            whereString: condition?.whereString(),
            whereArgs: condition?.whereArgs(),
          );

          assert(count == payloads.length);

          return payloads;
        },
        {'condition': condition},
      );

  @override
  Future<P> wasteById(id) => v(
        () async {
          final payload = await _table.selectByPk(id);
          await _table.deleteByPk(id);
          return pack(payload);
        },
        {'id': id},
      );
}
