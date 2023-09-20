import 'package:collection/collection.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';
import 'package:mem/framework/database/definition/exceptions.dart';
import 'package:mem/framework/database/definition/column/primary_key_definition.dart';

import 'column/foreign_key_definition.dart';

class TableDefinitionV2 {
  final String name;
  final Iterable<ColumnDefinitionV2> columnDefinitions;
  final String? singularName;

  TableDefinitionV2(this.name, this.columnDefinitions, {this.singularName}) {
    if (name.isEmpty) {
      throw TableDefinitionException('Table name is empty.');
    } else if (name.contains(' ')) {
      throw TableDefinitionException('Table name contains " ".');
    } else if (name.contains('-')) {
      throw TableDefinitionException('Table name contains "-".');
    }

    if (columnDefinitions.isEmpty) {
      throw TableDefinitionException('ColumnDefinitions are empty.');
    } else if (columnDefinitions.groupListsBy((c) => c.name).length !=
        columnDefinitions.length) {
      throw TableDefinitionException('Duplicate column name.');
    }
  }

  String buildCreateTableSql() => [
        'CREATE TABLE',
        name,
        '(',
        [
          columnDefinitions
              .map((columnDefinition) => columnDefinition.buildCreateTableSql())
              .join(', '),
          primaryKeyDefinitions.isEmpty
              ? null
              : 'PRIMARY KEY ( ${primaryKeyDefinitions.map((e) => e.name).join(', ')} )',
          foreignKeyDefinitions.isEmpty
              ? null
              : foreignKeyDefinitions
                  .map((e) => e.buildForeignKeySql())
                  .join(', '),
        ].where((element) => element != null).join(', '),
        ')',
      ].join(' ');

  Iterable<ColumnDefinitionV2> get primaryKeyDefinitions =>
      columnDefinitions.where((element) => element.isPrimaryKey);

  Iterable<ForeignKeyDefinitionV2> get foreignKeyDefinitions =>
      columnDefinitions.whereType<ForeignKeyDefinitionV2>();

  @override
  String toString() => [
        'TableDefinition',
        {
          'name': name,
          'columnDefinitions': columnDefinitions.map((e) => e.toString()),
          'singularName': singularName,
        },
      ].join(': ');
}

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
      ' ${columns.map((column) => column.buildCreateTableSql()).join(', ')}'
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
