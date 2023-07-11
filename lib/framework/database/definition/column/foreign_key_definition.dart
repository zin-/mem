import 'package:mem/framework/database/definition/exceptions.dart';
import 'package:mem/framework/database/definition/table_definition_v2.dart';

import 'column_definition.dart';

class ForeignKeyDefinition extends ColumnDefinition {
  final TableDefinitionV2 parentTableDefinition;

  ForeignKeyDefinition(
    this.parentTableDefinition,
  ) : super(
          'fk_${parentTableDefinition.singularName ?? (throw ColumnDefinitionException('Parent table: "${parentTableDefinition.name}" does not have singular name.'))}_id',
          parentTableDefinition.primaryKeys.length == 1
              ? parentTableDefinition.primaryKeys.single.type
              : throw UnimplementedError(
                  'Parent table: "${parentTableDefinition.name}" has multiple primary keys.',
                ),
          notNull: true,
        );

  String buildForeignKeySql() => 'FOREIGN KEY ($name)'
      ' REFERENCES ${parentTableDefinition.name}'
      '(${parentTableDefinition.primaryKeys.single.name})';
}
