import 'package:mem/database/database.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/repositories/_repository_v2.dart';
import 'package:mem/repositories/i/types.dart';

import '_database_tuple_entity_v2.dart';
import 'conditions.dart';

typedef UnpackedPayload = Map<AttributeName, dynamic>;

abstract class DatabaseTupleRepositoryV2<E extends DatabaseTupleEntityV2, P>
    implements RepositoryV2<E, P> {
  final Table _table;

  DatabaseTupleRepositoryV2(this._table);

  UnpackedPayload unpack(P payload);

  P pack(UnpackedPayload unpackedPayload);

  @override
  Future<P> receive(P payload) => v(
        {'payload': payload},
        () async {
          final entityMap = unpack(payload);

          entityMap[createdAtColumnName] = DateTime.now();

          final id = await _table.insert(entityMap);

          entityMap[idColumnName] = id;

          return pack(entityMap);
        },
      );

  @override
  Future<List<P>> ship([Condition? condition]) => v(
        {'condition': condition},
        () async => (await _table.select(
          whereString: condition?.whereString(),
          whereArgs: condition?.whereArgs(),
        ))
            .map((e) => pack(e))
            .toList(),
      );

  @override
  Future<P> shipById(id) => v(
        {'id': id},
        () async => pack(await _table.selectByPk(id)),
      );

  @override
  Future<P> replace(P payload) => v(
        {'payload': payload},
        () async {
          final entityMap = unpack(payload);

          entityMap[createdAtColumnName] = DateTime.now();

          await _table.updateByPk(
            entityMap[idColumnName],
            entityMap,
          );

          return pack(entityMap);
        },
      );

  @override
  Future<P> archive(P payload) => v(
        {'payload': payload},
        () async {
          final entityMap = unpack(payload);

          entityMap[archivedAtColumnName] = DateTime.now();

          await _table.updateByPk(
            entityMap[idColumnName],
            entityMap,
          );

          return pack(entityMap);
        },
      );

  @override
  Future<P> unarchive(P payload) => v(
        {'payload': payload},
        () async {
          final entityMap = unpack(payload);

          entityMap[archivedAtColumnName] = null;

          await _table.updateByPk(
            entityMap[idColumnName],
            entityMap,
          );

          return pack(entityMap);
        },
      );

  @override
  Future<P> wasteById(id) => v(
        {'id': id},
        () async {
          final payload = await _table.selectByPk(id);
          await _table.deleteByPk(id);
          return pack(payload);
        },
      );
}
