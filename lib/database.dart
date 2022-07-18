import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;

class Database {
  final String name;
  final int version;
  final List<TableDefinition> tables;

  static Future<Database> open(
    String name,
    int version,
    List<TableDefinition> tables,
  ) async =>
      await Database._(name, version, tables)._open();

  static Future<void> delete(String name) async =>
      sqflite.deleteDatabase(await _getDatabasePath(name));

  Database._(this.name, this.version, this.tables);

  late final sqflite.Database _database;

  Future<Database> _open() async {
    print('Platform is ${Platform.operatingSystem}');

    if (Platform.isAndroid) {
      _database = await sqflite.openDatabase(
        await _getDatabasePath(name),
        version: version,
        onCreate: (db, version) {
          for (var table in tables) {
            db.execute(table.buildCreateSql());
          }
        },
      );
    }

    return this;
  }

  static Future<String> _getDatabasePath(String name) async {
    if (Platform.isAndroid) {
      return path.join(await sqflite.getDatabasesPath(), name);
    } else {
      throw DatabaseException(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }
  }
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

  Future<int> insert(Database database, Map<String, dynamic> values) =>
      database._database.insert(name, values);

  Future<List<Map<String, dynamic>>> select(Database database) =>
      database._database.query(name);

  Future<List<Map<String, dynamic>>> selectWhere(
    Database database,
    Map<String, dynamic> where,
  ) =>
      database._database.query(
        name,
        where: where.keys.map((key) => '$key = ?').join(', '),
        whereArgs: where.values.toList(),
      );

  Future<int> update(
    Database database,
    Map<String, dynamic> values,
    Map<String, dynamic> where,
  ) =>
      database._database.update(
        name,
        values,
        where: where.keys.map((key) => '$key = ?').join(', '),
        whereArgs: where.values.toList(),
      );

  Future<int> delete(
    Database database,
    Map<String, dynamic> where,
  ) =>
      database._database.delete(
        name,
        where: where.keys.map((key) => '$key = ?').join(', '),
        whereArgs: where.values.toList(),
      );

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

  FieldDefinition(this.name, this.type);

  String buildFieldSql() => '$name ${type.value}';
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

enum FieldType { integer, text }

extension on FieldType {
  static final values = {FieldType.integer: 'INTEGER', FieldType.text: 'TEXT'};

  String get value => values[this]!;
}

class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);
}
