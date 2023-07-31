import 'package:mem/framework/database/definition/exceptions.dart';
import 'package:mem/framework/database/definition/table_definition_v2.dart';

class DatabaseDefinitionV2 {
  final String name;
  final int version;
  final List<TableDefinitionV2> tableDefinitions;

  DatabaseDefinitionV2(this.name, this.version, this.tableDefinitions) {
    if (name.isEmpty) {
      throw DatabaseDefinitionException('Database name is empty.');
    } else if (name.contains(' ')) {
      throw DatabaseDefinitionException('Database name contains " ".');
    } else if (name.contains('-')) {
      throw DatabaseDefinitionException('Database name contains "-".');
    }

    if (version < 1) {
      throw DatabaseDefinitionException('Version is less than 1.');
    }
  }

  @override
  String toString() => 'DatabaseDefinition'
      ' : {'
      ' name: $name,'
      ' version: $version,'
      ' tableDefinitions: ${tableDefinitions.map((e) => e.toString())}'
      ' }';
}
