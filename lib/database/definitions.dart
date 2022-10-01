import 'package:collection/collection.dart';
import 'package:mem/database/database.dart';

typedef DefD = DatabaseDefinition;

class DatabaseDefinition {
  final String name;
  final int version;
  final List<DefT> tableDefinitions;

  DatabaseDefinition(this.name, this.version, this.tableDefinitions) {
    if (name.isEmpty) {
      throw DatabaseDefinitionException('Database name is required.');
    } else if (name.contains(' ')) {
      throw DatabaseDefinitionException('Database name contains " ".');
    } else if (version < 1) {
      throw DatabaseDefinitionException('Minimum version is 1.');
    }
  }

  @override
  String toString() => 'Database definition'
      ' :: {'
      ' name: $name,'
      ' version: $version,'
      ' tables: ${tableDefinitions.map((defT) => defT.name)}'
      ' }';
}

typedef DefT = TableDefinition;

class TableDefinition {
  final String name;
  final List<ColumnDefinition> columns;

  TableDefinition(this.name, this.columns) {
    if (name.isEmpty) {
      throw DatabaseDefinitionException('Table name is required.');
    } else if (name.contains(' ')) {
      throw DatabaseDefinitionException('Table name contains " ".');
    } else if (columns.isEmpty) {
      throw DatabaseDefinitionException('Table columns are required.');
    } else if (columns.whereType<PrimaryKeyDefinition>().isEmpty) {
      throw DatabaseDefinitionException('Primary key is required.');
    } else if (columns.whereType<PrimaryKeyDefinition>().length > 1) {
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

  PrimaryKeyDefinition get primaryKey =>
      columns.whereType<PrimaryKeyDefinition>().first;

  @override
  String toString() => 'Table definition'
      ' :: {'
      ' name: $name'
      ', columns: $columns'
      ' }';
}

typedef DefC = ColumnDefinition;

class ColumnDefinition {
  final String name;
  final ColumnType type;
  final bool notNull;
  final dynamic defaultValue;

  ColumnDefinition(
    this.name,
    this.type, {
    this.notNull = true,
    this.defaultValue,
  }) {
    if (name.isEmpty) {
      throw DatabaseDefinitionException('Column name is required.');
    } else if (name.contains(' ')) {
      throw DatabaseDefinitionException('Column name contains " ".');
    }
  }

  String _onSQL() => '$name ${type._onSQL}'
      '${notNull ? ' NOT NULL' : ''}'
      // FIXME defaultValueがDateTimeなどの場合、動かない気がする
      '${defaultValue == null ? notNull ? '' : ' DEFAULT NULL' : ' DEFAULT $defaultValue'}';

  dynamic toTuple(dynamic value) {
    switch (type) {
      case ColumnType.integer:
      case ColumnType.text:
        return value;
      case ColumnType.datetime:
        return value == null ? null : (value as DateTime).toIso8601String();
    }
  }

  dynamic fromTuple(dynamic value) {
    switch (type) {
      case ColumnType.integer:
      case ColumnType.text:
        return value;
      case ColumnType.datetime:
        return value == null ? null : DateTime.parse(value);
    }
  }

  @override
  String toString() => 'Column definition :: { name: $name }';
}

typedef DefPK = PrimaryKeyDefinition;

class PrimaryKeyDefinition extends ColumnDefinition {
  final bool autoincrement;

  PrimaryKeyDefinition(
    super.name,
    super.type, {
    this.autoincrement = false,
  });

  @override
  String _onSQL() => '${super._onSQL()}'
      ' PRIMARY KEY'
      '${autoincrement ? ' AUTOINCREMENT' : ''}';

  @override
  String toString() => 'Primary key definition :: { name: $name }';
}

typedef DefFK = ForeignKeyDefinition;

class ForeignKeyDefinition extends ColumnDefinition {
  final TableDefinition parentTableDefinition;

  ForeignKeyDefinition(this.parentTableDefinition)
      : super(
          [
            parentTableDefinition.name,
            parentTableDefinition.primaryKey.name,
          ].join('_'),
          parentTableDefinition.primaryKey.type,
        );

  @override
  String _onSQL() => [
        super._onSQL(),
        'FOREIGN KEY ($name)'
            ' REFERENCES ${parentTableDefinition.name}'
            '(${parentTableDefinition.primaryKey.name})'
      ].join(', ');

  @override
  String toString() => 'Foreign key definition :: { name: $name }';
}

typedef TypeC = ColumnType;

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
