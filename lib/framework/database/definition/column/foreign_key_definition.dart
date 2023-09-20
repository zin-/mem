import 'package:mem/framework/database/definition/exceptions.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';

class ForeignKeyDefinitionV2 extends ColumnDefinitionV2 {
  final TableDefinitionV2 parentTableDefinition;

  ForeignKeyDefinitionV2(
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

class ForeignKeyDefinition extends ColumnDefinition {
  final TableDefinition parentTableDefinition;

  ForeignKeyDefinition(
    this.parentTableDefinition, {
    super.notNull,
  }) : super(
          [
            parentTableDefinition.name,
            parentTableDefinition.primaryKey.name,
          ].join('_'),
          parentTableDefinition.primaryKey.type,
        );

  @override
  String buildCreateTableSql() => [
        super.buildCreateTableSql(),
        'FOREIGN KEY ($name)'
            ' REFERENCES ${parentTableDefinition.name}'
            '(${parentTableDefinition.primaryKey.name})'
      ].join(', ');

  @override
  String toString() => 'Foreign key definition :: { name: $name }';
}
