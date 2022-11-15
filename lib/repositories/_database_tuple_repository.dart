import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger/api.dart';

const idColumnName = 'id';
const createdAtColumnName = 'createdAt';
const updatedAtColumnName = 'updatedAt';
const archivedAtColumnName = 'archivedAt';

abstract class DatabaseTupleEntity {
  late dynamic id;
  late DateTime? createdAt;
  late DateTime? updatedAt;
  late DateTime? archivedAt;

  DatabaseTupleEntity({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  bool isSaved() => id != null && createdAt != null;

  bool isArchived() => isSaved() && archivedAt != null;

  DatabaseTupleEntity.fromMap(Map<String, dynamic> valueMap)
      : id = valueMap[idColumnName],
        createdAt = valueMap[createdAtColumnName],
        updatedAt = valueMap[updatedAtColumnName],
        archivedAt = valueMap[archivedAtColumnName];

  Map<String, dynamic> toMap() => {
        idColumnName: id,
        createdAtColumnName: createdAt,
        updatedAtColumnName: updatedAt,
        archivedAtColumnName: archivedAt,
      };
}

final defaultColumnDefinitions = [
  DefC(createdAtColumnName, TypeC.datetime),
  DefC(updatedAtColumnName, TypeC.datetime, notNull: false),
  DefC(archivedAtColumnName, TypeC.datetime, notNull: false),
];

abstract class DatabaseTupleRepository<Entity extends DatabaseTupleEntity> {
  Future<Entity> receive(Entity entity) => v(
        {'entity': entity},
        () async {
          final insertingMap = entity.toMap()
            ..[createdAtColumnName] = entity.createdAt ?? DateTime.now();

          final id = await _table.insert(insertingMap);

          return fromMap(insertingMap..[idColumnName] = id);
        },
      );

  Future<List<Entity>> ship({
    Map<String, dynamic>? whereMap,
  }) =>
      v(
        {'whereMap': whereMap},
        () async {
          final where = whereMap?.entries
              .map((e) => e.value == null ? e.key : '${e.key} = ?')
              .join(' AND ');
          final whereArgs =
              whereMap?.values.where((value) => value != null).toList();
          return (await _table.select(
            where: where?.isEmpty == true ? null : where,
            whereArgs: whereArgs?.isEmpty == true ? null : whereArgs,
          ))
              .map((e) => fromMap(e))
              .toList();
        },
      );

  Future<Entity> shipById(dynamic id) => v(
        {'id': id},
        () async => fromMap(await _table.selectByPk(id)),
      );

  Future<Entity> update(Entity entity) => v(
        {'entity': entity},
        () async {
          final valueMap = entity.toMap();
          valueMap[updatedAtColumnName] = DateTime.now();

          await _table.updateByPk(entity.id, valueMap);

          return fromMap(valueMap);
        },
      );

  Future<Entity> archive(Entity entity) => v(
        {'entity': entity},
        () async {
          final valueMap = entity.toMap();
          valueMap[archivedAtColumnName] = DateTime.now();

          await _table.updateByPk(entity.id, valueMap);

          return fromMap(valueMap);
        },
      );

  Future<Entity> unarchive(Entity entity) => v(
        {'entity': entity},
        () async {
          final valueMap = entity.toMap();
          valueMap[archivedAtColumnName] = null;

          await _table.updateByPk(entity.id, valueMap);

          return fromMap(valueMap);
        },
      );

  Future<bool> discardById(dynamic id) => v(
        {'id': id},
        () async {
          int deletedCount = await _table.deleteByPk(id);

          return deletedCount == 1;
        },
      );

  Future<int> discardAll() => v(
        {},
        () async => _table.delete(),
      );

  Entity fromMap(Map<String, dynamic> valueMap);

  final Table _table;

  DatabaseTupleRepository(this._table);
}

Map<String, String?> buildNullableWhere(String columnName, bool? hasValue) => v(
      {'columnName': columnName, 'hasValue': hasValue},
      () {
        if (hasValue == null) {
          return {};
        } else {
          final a =
              hasValue ? '$columnName IS NOT NULL' : '$columnName IS NULL';
          return {a: null};
        }
      },
    );
