import 'package:mem/framework/database/database.dart';

class DatabaseDefinitionException extends DatabaseException {
  DatabaseDefinitionException(super.message);
}

class TableDefinitionException extends DatabaseException {
  TableDefinitionException(super.message);
}

class ColumnDefinitionException extends DatabaseDefinitionException {
  ColumnDefinitionException(super.message);
}
