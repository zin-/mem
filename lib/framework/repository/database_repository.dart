import 'dart:io';

import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';

class DatabaseRepository extends Repository<DatabaseDefinition>
    with Receiver<DatabaseDefinition, DatabaseAccessor> {
  static DatabaseRepository? _instance;

  final _cache = <String, DatabaseAccessor>{};

  DatabaseRepository._();

  factory DatabaseRepository() => _instance ??= DatabaseRepository._();

  @override
  Future<DatabaseAccessor> receive(DatabaseDefinition entity) => v(
        () async =>
            _cache[entity.name] ??
            await () async {
              final opened = await DatabaseFactory.open(entity);
              return _cache.putIfAbsent(entity.name, () => opened);
            }(),
        {
          "entity": entity,
        },
      );

  Future<File?> shipFileByNameIs(String name) => v(
        () async {
          final databaseFile = File(
            await DatabaseFactory.buildDatabasePath(name),
          );

          return await databaseFile.exists() ? databaseFile : null;
        },
        {
          "name": name,
        },
      );
}
