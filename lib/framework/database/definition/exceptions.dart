class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => message;
}

class DatabaseDefinitionException extends DatabaseException {
  DatabaseDefinitionException(super.message);
}

class TableDefinitionException extends DatabaseException {
  TableDefinitionException(super.message);
}

class ColumnDefinitionException extends DatabaseDefinitionException {
  ColumnDefinitionException(super.message);
}
