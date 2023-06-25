import 'dart:async';

import 'package:mem/framework/database/definitions/definition.dart';
import 'package:mem/framework/database/definitions/table_definition.dart';

abstract class Database {
  final DatabaseDefinition definition;
  var isOpen = false;
  final tables = <String, Table>{};

  Database(this.definition);

  Future<Database> open();

  Future<bool> close();

  Future<bool> delete();

  Future<T> checkExists<T>(
    FutureOr<T> Function() onTrue,
    FutureOr<T> Function() onFalse,
  );

  Table getTable(String name) {
    if (tables.containsKey(name)) {
      return tables[name]!;
    } else {
      throw DatabaseException(
          'Table: $name does not exist on Database: "${definition.name}".');
    }
  }

  Future<T> onOpened<T>(
    FutureOr<T> Function() onTrue,
    FutureOr<T> Function() onFalse,
  ) async =>
      isOpen ? await checkExists(onTrue, onFalse) : await onFalse();
}

abstract class Table {
  final TableDefinition definition;

  Table(this.definition);

  Future<int> insert(Map<String, dynamic> valueMap);

  Future<List<Map<String, dynamic>>> select({
    String? whereString,
    Iterable<dynamic>? whereArgs,
  });

  Future<Map<String, dynamic>> selectByPk(dynamic pk);

  Future<int> updateByPk(dynamic pk, Map<String, dynamic> value);

  Future<int> patchByPk(dynamic pk, Map<String, dynamic> value);

  Future<int> deleteByPk(dynamic pk);

  Future<int> delete();

  // TODO implement
  // bulkInsert();
  // bulkUpdate();

  Map<String, dynamic> convertTo(Map<String, dynamic> value) =>
      value.map((key, value) => MapEntry(
            key,
            definition.columns.where((f) => f.name == key).first.toTuple(value),
          ));

  Map<String, dynamic> convertFrom(Map<String, dynamic> value) =>
      value.map((key, value) => MapEntry(
            key,
            definition.columns
                .where((f) => f.name == key)
                .first
                .fromTuple(value),
          ));
}

class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => message;
}

class NotFoundException extends DatabaseException {
  NotFoundException(String targetName, String conditions)
      : super(
          'Not found.'
          ' {'
          ' target: $targetName'
          ', conditions: { $conditions }'
          ' }',
        );
}

class ParentNotFoundException extends NotFoundException {
  ParentNotFoundException(super.targetName, super.conditions);
}

class DatabaseDoesNotExistException extends DatabaseException {
  DatabaseDoesNotExistException(String databaseName)
      : super(
          'Database does not exist or closed.'
          ' databaseName: $databaseName',
        );
}
