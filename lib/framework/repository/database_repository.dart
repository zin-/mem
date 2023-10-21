import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';

class DatabaseRepository extends Repository<DatabaseDefinition> {
  final _cache = <String, DatabaseAccessor>{};

  @override
  Future<DatabaseAccessor> receive(DatabaseDefinition entity) => v(
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
