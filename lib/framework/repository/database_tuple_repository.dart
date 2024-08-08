import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/database_repository.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';

// FIXME byIdの引数の型のためにSavedEntityの型以外にIが必要になっている
//  Rにidの型情報が含まれているのに改めて渡す必要があるのはおかしい
//  DatabaseTupleに型情報を付与することでズレは発生しなくなった
//  ただ、これだと未保存のDatabaseTupleが
// FIXME SavedEntityはSavedDatabaseTupleをmixinしている必要があるが型制約を定義できていない
abstract class DatabaseTupleRepository<E extends Entity> extends Repository<E> {
  final DatabaseDefinition _databaseDefinition;
  final TableDefinition _tableDefinition;

  DatabaseTupleRepository(this._databaseDefinition, this._tableDefinition);

  DatabaseAccessor? _databaseAccessor;

  late final Future<DatabaseAccessor> _dbA = (() async => _databaseAccessor ??=
      await DatabaseRepository().receive(_databaseDefinition))();

  Future<int> count({
    Condition? condition,
  }) =>
      v(
        () async => (await _dbA).count(
          _tableDefinition,
          where: condition?.where(),
          whereArgs: condition?.whereArgs(),
        ),
        {
          'condition': condition,
        },
      );

  E pack(Map<String, dynamic> map);

  Future<E> receive(E entity, {DateTime? createdAt}) => v(
        () async {
          final entityMap = entity.toMap;

          entityMap[defColCreatedAt.name] = createdAt ?? DateTime.now();

          final id = await _databaseAccessor!.insert(
            _tableDefinition,
            entityMap,
          );

          entityMap[defPkId.name] = id;

          return pack(entityMap);
        },
        {
          'entity': entity,
          'createdAt': createdAt,
        },
      );
}
