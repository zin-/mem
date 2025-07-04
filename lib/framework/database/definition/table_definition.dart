import 'package:collection/collection.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';
import 'package:mem/framework/database/definition/exceptions.dart';

import 'column/foreign_key_definition.dart';

class TableDefinition {
  final String name;
  final Iterable<ColumnDefinition> columnDefinitions;
  final String? singularName;

  TableDefinition(this.name, this.columnDefinitions, {this.singularName}) {
    if (name.isEmpty) {
      throw TableDefinitionException('Table name is empty.');
    } else if (name.contains(' ')) {
      throw TableDefinitionException('Table name contains " ".');
    } else if (name.contains('-')) {
      throw TableDefinitionException('Table name contains "-".');
    }

    if (columnDefinitions.isEmpty) {
      throw TableDefinitionException('ColumnDefinitions are empty.');
    }
    final nameGrouped = columnDefinitions.groupListsBy((c) => c.name);
    if (nameGrouped.length != columnDefinitions.length) {
      final duplicateNames = nameGrouped.entries
          .where((e) => e.value.length > 1)
          .map((e) => e.value.first.name)
          .join(', ');
      throw TableDefinitionException(
        'Duplicate column name: $duplicateNames.',
      );
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

  Iterable<ColumnDefinition> get primaryKeyDefinitions =>
      columnDefinitions.where((element) => element.isPrimaryKey);

  Iterable<ForeignKeyDefinition> get foreignKeyDefinitions =>
      columnDefinitions.whereType<ForeignKeyDefinition>();

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
