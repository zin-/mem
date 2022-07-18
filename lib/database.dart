typedef DefT = TableDefinition;

class TableDefinition {
  final String name;
  final List<FieldDefinition> fields;

  TableDefinition(this.name, this.fields) {
    if (name.isEmpty) {
      throw DatabaseException('Table name is required.');
    } else if (fields.isEmpty) {
      throw DatabaseException('Table fields are required.');
    } else if (fields.whereType<PrimaryKeyDefinition>().isEmpty) {
      throw DatabaseException('Primary key is required.');
    } else if (fields.whereType<PrimaryKeyDefinition>().length > 1) {
      throw DatabaseException('Only one primary key is allowed.');
    }
  }

  @override
  String toString() => 'Database table definition: $name';

  String buildCreateSql() => 'CREATE TABLE'
      ' $name'
      ' ('
      ' ${fields.map((field) => field.buildFieldSql()).join(', ')}'
      ' )';
}

typedef DefF = FieldDefinition;

class FieldDefinition {
  final String name;
  final FieldType type;

  FieldDefinition(this.name, this.type);

  String buildFieldSql() => '$name ${type.value}';
}

typedef DefPK = PrimaryKeyDefinition;

class PrimaryKeyDefinition extends FieldDefinition {
  final bool autoincrement;

  PrimaryKeyDefinition(
    super.name,
    super.type, {
    this.autoincrement = false,
  });

  @override
  String buildFieldSql() => '${super.buildFieldSql()}'
      ' PRIMARY KEY'
      '${autoincrement ? ' AUTOINCREMENT' : ''}';
}

typedef TypeF = FieldType;

enum FieldType { integer, text }

extension on FieldType {
  static final values = {FieldType.integer: 'INTEGER', FieldType.text: 'TEXT'};

  String get value => values[this]!;
}

class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);
}
