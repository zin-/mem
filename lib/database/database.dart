import 'package:mem/database/definitions.dart';

abstract class DatabaseV2 {
  final DefD definition;
  final tables = <String, TableV2>{};

  DatabaseV2(this.definition);

  Future<DatabaseV2> open();

  Future<bool> delete();

  TableV2 getTable(String name) {
    if (tables.containsKey(name)) {
      return tables[name]!;
    } else {
      throw DatabaseException(
          'Table: $name does not exist on Database: ${definition.name}.');
    }
  }
}

abstract class TableV2 {
  final DefTV2 definition;

  TableV2(this.definition);

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
