import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';

const idColumnName = 'id';
const createdAtColumnName = 'createdAt';
const updatedAtColumnName = 'updatedAt';
const archivedAtColumnName = 'archivedAt';

class DatabaseTableRepository<Entity extends DatabaseTableEntity> {
  Future<Entity> receive(Map<String, dynamic> valueMap) => v(
        {'valueMap': valueMap},
        () async {
          final insertingMap = valueMap
            ..putIfAbsent(createdAtColumnName, () => DateTime.now());

          final id = await table.insert(insertingMap);

          return fromMap(insertingMap..putIfAbsent(idColumnName, () => id));
        },
      );

  Entity fromMap(Map<String, dynamic> valueMap) => v(
        {'valueMap': valueMap},
        () => throw UnimplementedError(),
      );

  Table table; // FIXME be private

  DatabaseTableRepository(this.table);
}

abstract class DatabaseTableEntity {
  final dynamic id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  DatabaseTableEntity({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });
}

final defaultColumnDefinitions = [
  DefC(createdAtColumnName, TypeC.datetime),
  DefC(updatedAtColumnName, TypeC.datetime, notNull: false),
  DefC(archivedAtColumnName, TypeC.datetime, notNull: false),
];
