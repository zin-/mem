import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/entity.dart';
import 'package:mem/framework/repository.dart';
import 'package:mem/logger/log_service.dart';

import 'database_tuple_entity.dart';
import 'conditions/conditions.dart';

// FIXME byIdの引数の型のためにRとは別にIが必要になっている
//  Rにidの型情報が含まれているのに改めて渡す必要があるのはおかしい
//  DatabaseTupleに型情報を付与することでズレは発生しなくなった
//  ただ、これだと未保存のDatabaseTupleが
abstract class DatabaseTupleRepository<E extends Entity, SavedEntity extends E,
    Id> implements Repository<E> {
  Map<String, dynamic> unpack(E entity);

  SavedEntity pack(Map<String, dynamic> tuple);

  @override
  Future<SavedEntity> receive(E entity) => v(
        () async {
          final entityMap = unpack(entity);

          entityMap[defColCreatedAt.name] = DateTime.now();

          final id = await _databaseAccessor!.insert(
            _tableDefinition,
            entityMap,
          );

          entityMap[defPkId.name] = id;

          return pack(entityMap);
        },
        entity,
      );

  Future<List<SavedEntity>> ship([Condition? condition]) => v(
        () async => (await _databaseAccessor!.select(
          _tableDefinition,
          where: condition?.where(),
          whereArgs: condition?.whereArgs(),
        ))
            .map((e) => pack(e))
            .toList(),
        condition,
      );

  Future<SavedEntity> shipById(Id id) => v(
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
        id,
      );

  Future<SavedEntity> replace(SavedEntity payload) => v(
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
        payload,
      );

  // Future<SavedEntity> archive(SavedEntity payload) => v(
  //       () async {
  //         final entityMap = unpack(payload);
  //
  //         entityMap[defColArchivedAt.name] = DateTime.now();
  //
  //         final condition = Equals(defPkId.name, entityMap[defPkId.name]);
  //         await _databaseAccessor!.update(
  //           _tableDefinition,
  //           entityMap,
  //           where: condition.where(),
  //           whereArgs: condition.whereArgs(),
  //         );
  //
  //         return pack(entityMap);
  //       },
  //       payload,
  //     );
  //
  // Future<SavedEntity> unarchive(SavedEntity payload) => v(
  //       () async {
  //         final entityMap = unpack(payload);
  //
  //         entityMap[defColUpdatedAt.name] = DateTime.now();
  //         entityMap[defColArchivedAt.name] = null;
  //
  //         final condition = Equals(defPkId.name, entityMap[defPkId.name]);
  //         await _databaseAccessor!.update(
  //           _tableDefinition,
  //           entityMap,
  //           where: condition.where(),
  //           whereArgs: condition.whereArgs(),
  //         );
  //
  //         return pack(entityMap);
  //       },
  //       payload,
  //     );
  //
  // Future<List<SavedEntity>> waste([Condition? condition]) => v(
  //       () async {
  //         final payloads = (await _databaseAccessor!.select(
  //           _tableDefinition,
  //           where: condition?.where(),
  //           whereArgs: condition?.whereArgs(),
  //         ))
  //             .map((e) => pack(e))
  //             .toList();
  //
  //         final count = await _databaseAccessor!.delete(
  //           _tableDefinition,
  //           where: condition?.where(),
  //           whereArgs: condition?.whereArgs(),
  //         );
  //
  //         assert(count == payloads.length);
  //
  //         return payloads;
  //       },
  //       condition,
  //     );

  Future<SavedEntity> wasteById(Id id) => v(
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
        id,
      );

  static DatabaseAccessor? _databaseAccessor;

  static set databaseAccessor(DatabaseAccessor databaseAccessor) =>
      _databaseAccessor ??= databaseAccessor;

  final TableDefinition _tableDefinition;

  DatabaseTupleRepository(this._tableDefinition);
}

abstract class DatabaseTupleRepositoryV2<E extends DatabaseTupleEntity, P>
    implements RepositoryV2<E, P> {
  static DatabaseAccessor? _databaseAccessor;

  static set databaseAccessor(DatabaseAccessor databaseAccessor) =>
      _databaseAccessor ??= databaseAccessor;

  final TableDefinition _tableDefinition;

  DatabaseTupleRepositoryV2(this._tableDefinition);

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
