import 'package:mem/framework/database/database.dart';

class DatabaseDefinitionException extends DatabaseException {
  DatabaseDefinitionException(super.message);
}

class ColumnDefinitionException extends DatabaseDefinitionException {
  ColumnDefinitionException(super.message);
}
