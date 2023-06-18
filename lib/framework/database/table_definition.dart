import 'package:collection/collection.dart';
import 'package:mem/database/database.dart';
import 'package:mem/framework/database/column_definition.dart';

class TableDefinition {
  final String name;
  final List<ColumnDefinition> columns;

  TableDefinition(this.name, this.columns) {
    if (name.isEmpty) {
      throw TableDefinitionException('Table name is required.');
    } else if (name.contains(' ')) {
      throw TableDefinitionException('Table name contains " ".');
    } else if (columns.isEmpty) {
      throw TableDefinitionException('Table columns are required.');
    } else if (columns.whereType<PrimaryKeyDefinition>().isEmpty) {
      throw TableDefinitionException('Primary key is required.');
    } else if (columns.whereType<PrimaryKeyDefinition>().length > 1) {
      throw TableDefinitionException('Only one primary key is allowed.');
    } else if (columns.groupListsBy((c) => c.name).length != columns.length) {
      throw TableDefinitionException(
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

class TableDefinitionException extends DatabaseException {
  TableDefinitionException(super.message);
}
