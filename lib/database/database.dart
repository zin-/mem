import 'package:flutter/foundation.dart';

import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';

abstract class Database {
  final String name;
  final int version;
  final List<TableDefinition> tables;

  Database(this.name, this.version, this.tables);

  Future<Database> open();

  Future<bool> delete();

  Future<int> insert(DefT table, Map<String, dynamic> value);

  Future<List<Map<String, dynamic>>> select(DefT table);

  Future<Map<String, dynamic>> selectById(DefT table, dynamic id);

  Future<int> updateById(DefT table, Map<String, dynamic> value, dynamic id);

  // FIXME delete()と干渉して嫌だ
  Future<int> deleteById(DefT table, dynamic id);
}

class DatabaseFactory {
  static Future<Database> open(
    String name,
    int version,
    List<TableDefinition> tables,
  ) async =>
      kIsWeb
          ? IndexedDatabase(name, version, tables)
          : SqliteDatabase(name, version, tables);
}

typedef DefT = TableDefinition;

class TableDefinition {
  final String name;
  final List<FieldDefinition> fields;

  TableDefinition(this.name, this.fields) {
    if (name.isEmpty) {
      throw DatabaseException('Table name is required.');
    } else if (fields.isEmpty) {
      throw DatabaseException('Table fields are required.');
    } else if (fields.whereType<PrimaryKeyDefinition>().isEmpty) {
      throw DatabaseException('Primary key is required.');
    } else if (fields.whereType<PrimaryKeyDefinition>().length > 1) {
      throw DatabaseException('Only one primary key is allowed.');
    }
  }

  Future<int> insert(Database database, Map<String, dynamic> value) =>
      database.insert(this, value);

  Future<List<Map<String, dynamic>>> select(Database database) =>
      database.select(this);

  Future<Map<String, dynamic>> selectById(
          Database database, dynamic id) async =>
      database.selectById(this, id);

  Future<int> update(
    Database database,
    Map<String, dynamic> value,
    dynamic id,
  ) async =>
      database.updateById(this, value, id);

  Future<int> delete(Database database, dynamic id) async =>
      database.deleteById(this, id);

  @override
  String toString() => 'Database table definition: $name';

  String buildCreateSql() => 'CREATE TABLE'
      ' $name'
      ' ('
      ' ${fields.map((field) => field.buildFieldSql()).join(', ')}'
      ' )';
}

typedef DefF = FieldDefinition;

class FieldDefinition {
  final String name;
  final FieldType type;
  final bool notNull;

  FieldDefinition(this.name, this.type, {this.notNull = true});

  String buildFieldSql() => '$name ${type.value}${notNull ? ' NOT NULL' : ''}';
}

typedef DefPK = PrimaryKeyDefinition;

class PrimaryKeyDefinition extends FieldDefinition {
  final bool autoincrement;

  PrimaryKeyDefinition(
    super.name,
    super.type, {
    this.autoincrement = false,
  });

  @override
  String buildFieldSql() => '${super.buildFieldSql()}'
      ' PRIMARY KEY'
      '${autoincrement ? ' AUTOINCREMENT' : ''}';
}

typedef TypeF = FieldType;

enum FieldType { integer, text, datetime }

extension on FieldType {
  static final values = {
    FieldType.integer: 'INTEGER',
    FieldType.text: 'TEXT',
    FieldType.datetime: 'TIMESTAMP',
  };

  String get value => values[this]!;
}

class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);
}
