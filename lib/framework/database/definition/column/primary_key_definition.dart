import 'package:mem/framework/database/definition/column/integer_column_definition.dart';

class PrimaryKeyDefinition extends IntegerColumnDefinition {
  PrimaryKeyDefinition(super.name, {super.notNull});
}
