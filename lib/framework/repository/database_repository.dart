import 'dart:io';
import 'package:mem/databases/database.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:path/path.dart' as path;

class DatabaseRepository extends Repository<DatabaseDefinition> {
  static DatabaseRepository? _instance;

  DatabaseRepository._();

  factory DatabaseRepository() => _instance ??= DatabaseRepository._();

  Future<DriftDatabaseAccessor> receive(DatabaseDefinition entity) => v(
        () async => DriftDatabaseAccessor(),
        {"entity": entity},
      );

  Future<File?> shipFileByNameIs(String name) => v(
        () async => getDatabaseFile(),
        {"name": name},
      );

  Future<void> replace(String name, File backup) => v(
        () async {
          await DatabaseTupleRepository.close();

          final current = (await getDatabaseFile())!;
          final originalPath = current.path;
          final currentName = path.basename(originalPath);
          await current.rename(
              originalPath.replaceFirst(currentName, "past-$currentName"));

          await backup.copy(originalPath);
        },
        {'name': name, 'backup': backup},
      );

  @override
  waste({Condition? condition}) {
    throw UnimplementedError();
  }
}
