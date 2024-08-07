import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/condition/conditions.dart';

// FIXME byIdの引数の型のためにSavedEntityの型以外にIが必要になっている
//  Rにidの型情報が含まれているのに改めて渡す必要があるのはおかしい
//  DatabaseTupleに型情報を付与することでズレは発生しなくなった
//  ただ、これだと未保存のDatabaseTupleが
// FIXME SavedEntityはSavedDatabaseTupleをmixinしている必要があるが型制約を定義できていない
abstract class DatabaseTupleRepository<E extends EntityV1,
    SavedEntity extends E, Id> implements RepositoryV1<E, SavedEntity> {
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

  Future<int> count({
    Condition? condition,
  }) =>
      v(
        () async => await _databaseAccessor!.count(
          _tableDefinition,
          where: condition?.where(),
          whereArgs: condition?.whereArgs(),
        ),
        {
          "condition": condition,
        },
      );

  Future<List<SavedEntity>> ship({
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () async => (await _databaseAccessor!.select(
          _tableDefinition,
          groupBy: groupBy?.toQuery,
          extraColumns: groupBy?.toExtraColumns,
          where: condition?.where(),
          whereArgs: condition?.whereArgs(),
          orderBy: orderBy?.isEmpty != false
              ? null
              : orderBy?.map((e) => e.toQuery()).join(", "),
          offset: offset,
          limit: limit,
        ))
            .map((e) => pack(e))
            .toList(),
        {
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
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

  Future<SavedEntity?> findOneBy({
    Condition? condition,
    List<OrderBy>? orderBy,
  }) =>
      v(
        () async => await ship(
          condition: condition,
          orderBy: orderBy,
          limit: 1,
        ).then((value) => value.length == 1 ? value.single : null),
        {
          "condition": condition,
          "orderBy": orderBy,
        },
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

  Future<SavedEntity> archive(SavedEntity payload) => v(
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
        payload,
      );

  Future<SavedEntity> unarchive(SavedEntity payload) => v(
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
        payload,
      );

  Future<List<SavedEntity>> waste([Condition? condition]) => v(
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
        condition,
      );

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

  static Future<void> close() => v(
        () async {
          await _databaseAccessor?.close();
          _databaseAccessor = null;
        },
      );

  static DatabaseAccessor? _databaseAccessor;

  static set databaseAccessor(DatabaseAccessor? databaseAccessor) =>
      _databaseAccessor = databaseAccessor;

  final TableDefinition _tableDefinition;

  DatabaseTupleRepository(this._tableDefinition);
}
