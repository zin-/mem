import 'package:mem/framework/database/definition/column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

class ForeignKeyDefinition extends ColumnDefinition {
  final TableDefinition parentTableDefinition;

  ForeignKeyDefinition(
    this.parentTableDefinition, {
    super.notNull,
    super.defaultValue,
  }) : super(
          [
            parentTableDefinition.name,
            parentTableDefinition.primaryKey.name,
          ].join('_'),
          parentTableDefinition.primaryKey.type,
        );

  @override
  String onSQL() => [
        super.onSQL(),
        'FOREIGN KEY ($name)'
            ' REFERENCES ${parentTableDefinition.name}'
            '(${parentTableDefinition.primaryKey.name})'
      ].join(', ');

  @override
  String toString() => 'Foreign key definition :: { name: $name }';
}
