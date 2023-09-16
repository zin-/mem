import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition_v2.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/logger/log_service.dart';

// TODO #222 Repositoryとして整理する
class DatabaseRepository {
  final _cache = <String, DatabaseAccessor>{};

  Future<DatabaseAccessor> receive(DatabaseDefinitionV2 entity) => v(
        () async {
          return _cache[entity.name] ??
              await () async {
                final opened = await DatabaseFactory.open(entity);
                return _cache.putIfAbsent(entity.name, () => opened);
              }();
        },
        entity,
      );

  DatabaseRepository._();

  static DatabaseRepository? _instance;

  factory DatabaseRepository() => _instance ??= DatabaseRepository._();
}
