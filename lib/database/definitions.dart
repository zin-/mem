import 'package:collection/collection.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions/column_definition.dart';

class DatabaseDefinition {
  final String name;
  final int version;
  final List<TableDefinition> tableDefinitions;

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
      ' ${columns.map((column) => column.onSQL()).join(', ')}'
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

class DatabaseDefinitionException extends DatabaseException {
  DatabaseDefinitionException(super.message);
}
