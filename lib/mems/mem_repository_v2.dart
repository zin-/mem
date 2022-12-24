import 'package:flutter/material.dart';
import 'package:mem/core/errors.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/database/database.dart' as db;
import 'package:mem/logger/i/api.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/i/_database_tuple_repository_v2.dart';
import 'package:mem/repositories/i/conditions.dart';
import 'package:mem/repositories/mem_entity.dart';

class MemRepositoryV2 extends DatabaseTupleRepositoryV2<MemEntityV2, Mem> {
  Future<List<Mem>> shipByCondition(bool? archived, bool? done) => v(
          {
            'archived': archived,
            'done': done,
          },
          () => super.ship(
                And([
                  archived == null
                      ? null
                      : archived
                          ? IsNull(archivedAtColumnName)
                          : IsNotNull(archivedAtColumnName),
                  done == null
                      ? null
                      : done
                          ? IsNull(defMemDoneAt.name)
                          : IsNotNull(defMemDoneAt.name),
                ].whereType<Condition>()),
              ));

  @override
  Mem pack(UnpackedPayload unpackedPayload) {
    final memEntity = MemEntityV2.fromMap(unpackedPayload);

    return Mem(
      name: memEntity.name,
      doneAt: memEntity.doneAt,
      notifyOn: memEntity.notifyOn,
      notifyAt: memEntity.notifyAt == null
          ? null
          : TimeOfDay.fromDateTime(memEntity.notifyAt!),
      id: memEntity.id,
      createdAt: memEntity.createdAt,
      updatedAt: memEntity.updatedAt,
      archivedAt: memEntity.archivedAt,
    );
    // TODO: implement pack
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  MemRepositoryV2._(super.table);

  static MemRepositoryV2? _instance;

  factory MemRepositoryV2([db.Table? table]) {
    var tmp = _instance;

    if (tmp == null) {
      if (table == null) {
        throw InitializationError();
      }
      _instance = tmp = MemRepositoryV2._(table);
    }

    return tmp;
  }

  static resetWith(MemRepositoryV2? memRepository) =>
      _instance = memRepository;
}
