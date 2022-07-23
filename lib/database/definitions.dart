import "package:collection/collection.dart";

import 'package:mem/database/database.dart';

typedef DefD = DatabaseDefinition;

class DatabaseDefinition {
  final String name;
  final int version;
  final List<TableDefinitionV2> tableDefinitions;

  DatabaseDefinition(this.name, this.version, this.tableDefinitions) {
    if (name.isEmpty) {
      throw DatabaseDefinitionException('Database name is required.');
    } else if (version < 1) {
      throw DatabaseDefinitionException('Minimum version is 1.');
    }
  }

  @override
  String toString() => 'Database definition.'
      ' {'
      ' name: $name,'
      ' version: $version,'
      ' tables: $tableDefinitions'
      ' }';
}

typedef DefTV2 = TableDefinitionV2;

class TableDefinitionV2 {
  final String name;
  final List<ColumnDefinition> columns;

  TableDefinitionV2(this.name, this.columns) {
    if (name.isEmpty) {
      throw DatabaseDefinitionException('Table name is required.');
    } else if (columns.isEmpty) {
      throw DatabaseDefinitionException('Table columns are required.');
    } else if (columns.whereType<PrimaryKeyDefinitionV2>().isEmpty) {
      throw DatabaseDefinitionException('Primary key is required.');
    } else if (columns.whereType<PrimaryKeyDefinitionV2>().length > 1) {
      throw DatabaseDefinitionException('Only one primary key is allowed.');
    } else if (columns.groupListsBy((c) => c.name).length != columns.length) {
      throw DatabaseDefinitionException(
          'Duplicated column names are not allowed.');
    }
  }

  String buildCreateTableSql() => 'CREATE TABLE'
      ' $name'
      ' ('
      ' ${columns.map((column) => column._onSQL()).join(', ')}'
      ' )';

  @override
  String toString() => 'Table definition.'
      ' {'
      ' name: $name'
      ', columns: $columns'
      ' }';
}

typedef DefC = ColumnDefinition;

class ColumnDefinition {
  final String name;
  final ColumnType type;
  final bool notNull;

  ColumnDefinition(this.name, this.type, {this.notNull = true}) {
    if (name.isEmpty) {
      throw DatabaseDefinitionException('Column name is required.');
    }
  }

  String _onSQL() => '$name ${type._onSQL}${notNull ? ' NOT NULL' : ''}';

  @override
  String toString() => 'Column definition. { name: $name }';
}

typedef DefPKV2 = PrimaryKeyDefinitionV2;

class PrimaryKeyDefinitionV2 extends ColumnDefinition {
  final bool autoincrement;

  PrimaryKeyDefinitionV2(
    super.name,
    super.type, {
    this.autoincrement = false,
  });

  @override
  String _onSQL() => '${super._onSQL()}'
      ' PRIMARY KEY'
      '${autoincrement ? ' AUTOINCREMENT' : ''}';
}

typedef TypeCV2 = ColumnType;

enum ColumnType { integer, text, datetime }

extension on ColumnType {
  static final _onSQLs = {
    ColumnType.integer: 'INTEGER',
    ColumnType.text: 'TEXT',
    ColumnType.datetime: 'TIMESTAMP',
  };

  String get _onSQL => _onSQLs[this]!;
}

class DatabaseDefinitionException extends DatabaseException {
  DatabaseDefinitionException(super.message);
}
