import 'package:mem/framework/database/definition/exceptions.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

import 'column_definition.dart';

class ForeignKeyDefinition extends ColumnDefinitionV2 {
  final TableDefinitionV2 parentTableDefinition;

  ForeignKeyDefinition(
    this.parentTableDefinition,
  ) : super(
          'fk_${parentTableDefinition.singularName ?? (throw ColumnDefinitionException('Parent table: "${parentTableDefinition.name}" does not have singular name.'))}_id',
          parentTableDefinition.primaryKeyDefinitions.length == 1
              ? parentTableDefinition.primaryKeyDefinitions.single.type
              : throw UnimplementedError(
                  'Parent table: "${parentTableDefinition.name}" has multiple primary keys.',
                ),
          notNull: true,
        );

  String buildForeignKeySql() => 'FOREIGN KEY ($name)'
      ' REFERENCES ${parentTableDefinition.name}'
      '(${parentTableDefinition.primaryKeyDefinitions.single.name})';
}
