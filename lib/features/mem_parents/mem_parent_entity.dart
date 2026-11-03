import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart' as drift_database;
import 'package:mem/features/mem_parents/mem_parent.dart';
import 'package:mem/framework/repository/entity.dart';

class MemParentEntity implements Entity<int> {
  final int memId;
  final int parentMemId;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  MemParentEntity(
    this.memId,
    this.parentMemId,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  );

  factory MemParentEntity.fromTuple(dynamic row) => MemParentEntity(
        row.memId,
        row.parentMemId,
        row.id,
        row.createdAt,
        row.updatedAt,
        row.archivedAt,
      );
}

drift_database.MemParentsCompanion convertIntoMemParentsInsertable(
  MemParent domain,
) =>
    drift_database.MemParentsCompanion(
      memId: Value(domain.memId),
      parentMemId: Value(domain.parentMemId),
      createdAt: Value(DateTime.now()),
    );
