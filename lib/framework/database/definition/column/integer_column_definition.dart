import 'package:mem/framework/database/definition/column/column_definition.dart';

class IntegerColumnDefinition extends ColumnDefinition {
  IntegerColumnDefinition(String name, {super.notNull})
      : super(name, 'INTEGER');
}
