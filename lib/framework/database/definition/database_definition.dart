import 'package:mem/framework/database/definition/exceptions.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/entity.dart';

class DatabaseDefinition with Entity {
  final String name;
  final int version;
  final List<TableDefinition> tableDefinitions;

  DatabaseDefinition(this.name, this.version, this.tableDefinitions) {
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
  Map<String, dynamic> get toMap => {
        'name': name,
        'version': version,
        'tableDefinitions': tableDefinitions.map((e) => e.toString())
      };

  @override
  Entity updatedWith(Function(dynamic v) update) {
    // TODO: implement updatedWith
    throw UnimplementedError();
  }
}
