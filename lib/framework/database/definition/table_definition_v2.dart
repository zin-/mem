import 'package:collection/collection.dart';
import 'package:mem/framework/database/definition/exceptions.dart';

import 'column/column_definition.dart';

class TableDefinitionV2 {
  final String name;
  final Iterable<ColumnDefinition> columnDefinitions;

  TableDefinitionV2(this.name, this.columnDefinitions) {
    if (name.isEmpty) {
      throw TableDefinitionException('Table name is required.');
    } else if (name.contains(' ')) {
      throw TableDefinitionException('Table name contains " ".');
    } else if (name.contains('-')) {
      throw TableDefinitionException('Table name contains "-".');
    }

    if (columnDefinitions.isEmpty) {
      throw TableDefinitionException('ColumnDefinitions are empty.');
    } else if (columnDefinitions.groupListsBy((c) => c.name).length !=
        columnDefinitions.length) {
      throw TableDefinitionException(
        'Duplicated column names are not allowed.',
      );
    }
  }

  // TODO fkの扱い
  String buildCreateTableSql() {
    final pks = columnDefinitions.where((element) => element.isPrimaryKey);

    return [
      'CREATE TABLE',
      name,
      '(',
      [
        columnDefinitions
            .map((columnDefinition) => columnDefinition.buildCreateTableSql())
            .join(', '),
        pks.isEmpty
            ? null
            : 'PRIMARY KEY ( ${pks.map((e) => e.name).join(', ')} )',
      ].where((element) => element != null).join(', '),
      ')',
    ].join(' ');
  }

  @override
  String toString() => 'TableDefinition'
      ' : {'
      ' name: $name'
      ', columnDefinitions: ${columnDefinitions.map((e) => e.name)}'
      ' }';
}
