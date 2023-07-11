import 'package:collection/collection.dart';

import 'column/column_definition.dart';
import 'column/foreign_key_definition.dart';
import 'exceptions.dart';

class TableDefinitionV2 {
  final String name;
  final Iterable<ColumnDefinition> columnDefinitions;
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

  String buildCreateTableSql() {
    final foreignKeys = columnDefinitions.whereType<ForeignKeyDefinition>();

    return [
      'CREATE TABLE',
      name,
      '(',
      [
        columnDefinitions
            .map((columnDefinition) => columnDefinition.buildCreateTableSql())
            .join(', '),
        primaryKeys.isEmpty
            ? null
            : 'PRIMARY KEY ( ${primaryKeys.map((e) => e.name).join(', ')} )',
        foreignKeys.isEmpty
            ? null
            : foreignKeys.map((e) => e.buildForeignKeySql()).join(', '),
      ].where((element) => element != null).join(', '),
      ')',
    ].join(' ');
  }

  Iterable<ColumnDefinition> get primaryKeys =>
      columnDefinitions.where((element) => element.isPrimaryKey);

  @override
  String toString() => [
        'TableDefinition',
        {
          'name': name,
          'columnDefinitions': columnDefinitions,
          'singularName': singularName,
        },
      ].join(': ');
}
