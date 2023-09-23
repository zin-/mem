import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';

class ForeignKeyDefinition extends ColumnDefinition {
  final TableDefinition parentTableDefinition;

  ForeignKeyDefinition(
    this.parentTableDefinition,
  ) : super(
          // FIXME fk_hoge_idにしたいが、既にhoges_idで定義されていてmigrationができない
          // ISSUE #230 modify column name
          // 'fk_${parentTableDefinition.singularName ?? (throw ColumnDefinitionException('Parent table: "${parentTableDefinition.name}" does not have singular name.'))}_id',
          "${parentTableDefinition.name}_id",
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
