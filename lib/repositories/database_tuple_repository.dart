import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/repository.dart';

import 'database_tuple_entity.dart';
import 'conditions/conditions.dart';

abstract class DatabaseTupleRepository<E extends DatabaseTupleEntity, P>
    implements RepositoryV2<E, P> {
  static DatabaseAccessor? _databaseAccessor;

  static set databaseAccessor(DatabaseAccessor databaseAccessor) =>
      _databaseAccessor ??= databaseAccessor;

  final TableDefinition _tableDefinition;

  DatabaseTupleRepository(this._tableDefinition);

  Map<String, dynamic> unpack(P payload);

  P pack(Map<String, dynamic> unpackedPayload);

  @override
  Future<P> receive(P payload) => v(
        () async {
          final entityMap = unpack(payload);

          entityMap[defColCreatedAt.name] = DateTime.now();

          final id = await _databaseAccessor!.insert(
            _tableDefinition,
            entityMap,
          );

          entityMap[defPkId.name] = id;

          return pack(entityMap);
        },
        {'payload': payload},
      );

  @override
  Future<List<P>> ship([Condition? condition]) => v(
        () async => (await _databaseAccessor!.select(
          _tableDefinition,
          where: condition?.where(),
          whereArgs: condition?.whereArgs(),
        ))
            .map((e) => pack(e))
            .toList(),
        {'condition': condition},
      );

  @override
  Future<P> shipById(id) => v(
        () async {
          final condition = Equals(defPkId.name, id);
          return pack(
            (await _databaseAccessor!.select(
              _tableDefinition,
              where: condition.where(),
              whereArgs: condition.whereArgs(),
            ))
                .single,
          );
        },
        {'id': id},
      );

  @override
  Future<P> replace(P payload) => v(
        () async {
          final entityMap = unpack(payload);

          entityMap[defColUpdatedAt.name] = DateTime.now();

          final condition = Equals(defPkId.name, entityMap[defPkId.name]);
          await _databaseAccessor!.update(
            _tableDefinition,
            entityMap,
            where: condition.where(),
            whereArgs: condition.whereArgs(),
          );

          return pack(entityMap);
        },
        {'payload': payload},
      );

  @override
  Future<P> archive(P payload) => v(
        () async {
          final entityMap = unpack(payload);

          entityMap[defColArchivedAt.name] = DateTime.now();

          final condition = Equals(defPkId.name, entityMap[defPkId.name]);
          await _databaseAccessor!.update(
            _tableDefinition,
            entityMap,
            where: condition.where(),
            whereArgs: condition.whereArgs(),
          );

          return pack(entityMap);
        },
        {'payload': payload},
      );

  @override
  Future<P> unarchive(P payload) => v(
        () async {
          final entityMap = unpack(payload);

          entityMap[defColUpdatedAt.name] = DateTime.now();
          entityMap[defColArchivedAt.name] = null;

          final condition = Equals(defPkId.name, entityMap[defPkId.name]);
          await _databaseAccessor!.update(
            _tableDefinition,
            entityMap,
            where: condition.where(),
            whereArgs: condition.whereArgs(),
          );

          return pack(entityMap);
        },
        {'payload': payload},
      );

  @override
  Future<List<P>> waste([Condition? condition]) => v(
        () async {
          final payloads = (await _databaseAccessor!.select(
            _tableDefinition,
            where: condition?.where(),
            whereArgs: condition?.whereArgs(),
          ))
              .map((e) => pack(e))
              .toList();

          final count = await _databaseAccessor!.delete(
            _tableDefinition,
            where: condition?.where(),
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
          final condition = Equals(defPkId.name, id);
          final payload = (await _databaseAccessor!.select(
            _tableDefinition,
            where: condition.where(),
            whereArgs: condition.whereArgs(),
          ))
              .single;
          await _databaseAccessor!.delete(
            _tableDefinition,
            where: condition.where(),
            whereArgs: condition.whereArgs(),
          );
          return pack(payload);
        },
        {'id': id},
      );
}
