import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/features/logger/log_service.dart';

abstract class DatabaseTupleRepository<DOMAIN, ID, ENTITY extends Entity<ID>>
    extends Repository {
  static final _driftAccessor = DriftDatabaseAccessor();
  static final Map<TableDefinition, Repository> _repositories = {};

  // ignore: unused_field
  final DatabaseDefinition _databaseDefinition;
  final TableDefinition _tableDefinition;

  DatabaseTupleRepository(this._databaseDefinition, this._tableDefinition) {
    _repositories[_tableDefinition] = this;
  }

  static Future close() => v(
        () async {
          await DriftDatabaseAccessor().close();
          DriftDatabaseAccessor.reset();
        },
      );

  Future<int> count({
    Condition? condition,
  }) =>
      v(
        () async => _driftAccessor.count(
          _tableDefinition,
          condition: condition,
        ),
        {'condition': condition},
      );

  convert(DOMAIN domain) => throw UnimplementedError();

  Future<ENTITY> receiveV2(DOMAIN domain) => v(
        () async {
          final inserted = await _driftAccessor.insertV2(domain);
          return List<ENTITY>.from([inserted]).single;
        },
        {'domain': domain},
      );

  Future<List<ENTITY>> shipV2({
    Condition? condition,
    List<TableDefinition>? loadChildren,
  }) =>
      v(
        () async {
          final rows = await _driftAccessor.selectV2(
            _tableDefinition,
            condition: condition,
            loadChildren: loadChildren,
          );
          return List<ENTITY>.from(rows);
        },
        {'condition': condition},
      );

  Future<ENTITY> shipById(int id) => v(
        () async {
          final row = await _driftAccessor.selectV2(
            _tableDefinition,
            condition: Equals(defPkId, id),
          );
          return List<ENTITY>.from(row).first;
        },
        {'id': id},
      );

  Future<ENTITY> replaceV2(ENTITY entity) => v(
        () async {
          final updated = await _driftAccessor.updateV2(entity);
          return List<ENTITY>.from([updated]).single;
        },
        {'entity': entity},
      );

  Future<List<ENTITY>> wasteV2({Condition? condition}) => v(
        () async {
          // TODO 子Entityを削除する

          final deleted = await _driftAccessor.deleteV2(
            _tableDefinition,
            condition: condition,
          );
          return List<ENTITY>.from(deleted);
        },
        {'condition': condition},
      );
}
