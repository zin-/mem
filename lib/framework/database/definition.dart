import 'package:mem/database/database.dart';
import 'package:mem/framework/database/table_definition.dart';

class DatabaseDefinition {
  final String name;
  final int version;
  final List<TableDefinition> tableDefinitions;

  DatabaseDefinition(this.name, this.version, this.tableDefinitions) {
    if (name.isEmpty) {
      throw DatabaseDefinitionException('Database name is required.');
    } else if (name.contains(' ')) {
      throw DatabaseDefinitionException('Database name contains " ".');
    }

    if (version < 1) {
      throw DatabaseDefinitionException('Minimum version is 1.');
    }
  }

  @override
  String toString() => 'Database definition'
      ' :: {'
      ' name: $name,'
      ' version: $version,'
      ' tables: ${tableDefinitions.map((defT) => defT.name)}'
      ' }';
}

class DatabaseDefinitionException extends DatabaseException {
  DatabaseDefinitionException(super.message);
}
