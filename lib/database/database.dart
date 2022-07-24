import 'package:mem/database/definitions.dart';

abstract class Database {
  final DefD definition;
  final tables = <String, Table>{};

  Database(this.definition);

  Future<Database> open();

  Future<bool> delete();

  Table getTable(String name) {
    if (tables.containsKey(name)) {
      return tables[name]!;
    } else {
      throw DatabaseException(
          'Table: $name does not exist on Database: ${definition.name}.');
    }
  }
}

abstract class Table {
  final DefT definition;

  Table(this.definition);

  Future<int> insert(Map<String, dynamic> value);

  Future<List<Map<String, dynamic>>> select();

  Future<Map<String, dynamic>> selectByPk(dynamic pk);

  Future<int> updateByPk(dynamic pk, Map<String, dynamic> value);

  Future<int> deleteByPk(dynamic pk);

  Future<int> delete();

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
