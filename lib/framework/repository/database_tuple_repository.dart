import 'dart:math' as math;

import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/load_child_spec.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/features/logger/log_service.dart';

const _cascadeChunkSize = 900;

/// Drift（SQLite）経由でテーブル行を [Entity] として読み書きするリポジトリの基底。
///
/// [receive]・[ship]・[shipById]・[replace]・[waste] は、ルートの [Repository] で説明した
/// 「倉庫」に合わせた動詞である（ドメイン値の受け取り・送り出し・置き換え・廃棄）。
abstract class DatabaseTupleRepository<DOMAIN, ID, ENTITY extends Entity<ID>>
    extends Repository {
  static DriftDatabaseAccessor get _driftAccessor => DriftDatabaseAccessor();

  // ignore: unused_field
  final DatabaseDefinition _databaseDefinition;
  final TableDefinition _tableDefinition;

  DatabaseTupleRepository(this._databaseDefinition, this._tableDefinition);

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

  Future<ENTITY> receive(DOMAIN domain) => v(
        () async {
          final inserted = await _driftAccessor.insertEntity(domain);
          return List<ENTITY>.from([inserted]).single;
        },
        {'domain': domain},
      );

  Future<List<ENTITY>> ship({
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
    List<LoadChildSpec>? loadChildren,
  }) =>
      v(
        () async {
          final rows = await _driftAccessor.selectEntities(
            _tableDefinition,
            condition: condition,
            groupBy: groupBy,
            orderBy: orderBy,
            offset: offset,
            limit: limit,
            loadChildren: loadChildren,
          );
          return List<ENTITY>.from(rows);
        },
        {
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
          'loadChildren': loadChildren,
        },
      );

  Future<ENTITY> shipById(
    int id, {
    List<LoadChildSpec>? loadChildren,
  }) =>
      v(
        () async {
          final row = await _driftAccessor.selectEntities(
            _tableDefinition,
            condition: Equals(defPkId, id),
            loadChildren: loadChildren,
          );
          return List<ENTITY>.from(row).first;
        },
        {'id': id, 'loadChildren': loadChildren},
      );

  Future<ENTITY> replace(ENTITY entity) => v(
        () async {
          final updated = await _driftAccessor.updateEntity(entity);
          return List<ENTITY>.from([updated]).single;
        },
        {'entity': entity},
      );

  Future<List<ENTITY>> waste({Condition? condition}) => v(
        () async {
          await _wasteChildRowsReferencingParent(condition);

          final deleted = await _driftAccessor.deleteEntities(
            _tableDefinition,
            condition: condition,
          );
          return List<ENTITY>.from(deleted);
        },
        {'condition': condition},
      );

  // TODO: wasteだけでなく、archiveでも使えるようにする
  Future<void> _wasteChildRowsReferencingParent(
    Condition? parentCondition,
  ) async {
    final parentTable = _tableDefinition;

    final parentIds = await _driftAccessor
        .selectEntities(
          parentTable,
          condition: parentCondition,
        )
        .then((rows) => rows.map((row) => (row as dynamic).id as int).toList());

    if (parentIds.isEmpty) return;

    for (var i = 0; i < parentIds.length; i += _cascadeChunkSize) {
      final end = math.min(
        i + _cascadeChunkSize,
        parentIds.length,
      );
      final chunk = parentIds.sublist(i, end);
      for (final childTable in _databaseDefinition.tableDefinitions) {
        if (childTable.name == parentTable.name) continue;
        for (final fk in childTable.foreignKeyDefinitions) {
          if (fk.parentTableDefinition.name != parentTable.name) continue;
          final inCondition = In(fk.name, chunk);
          if (!_driftAccessor.conditionDriftResolvable(
              childTable, inCondition)) {
            throw StateError(
              'waste cascade: cannot resolve In(${fk.name}) on '
              '${childTable.name}',
            );
          }
          await _driftAccessor.deleteEntities(
            childTable,
            condition: inCondition,
          );
        }
      }
    }
  }
}
