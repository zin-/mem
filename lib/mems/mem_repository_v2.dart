import 'package:mem/core/errors.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/database/database.dart';
import 'package:mem/repositories/i/_database_tuple_repository_v2.dart';
import 'package:mem/repositories/mem_entity.dart';

class MemRepositoryV2 extends DatabaseTupleRepositoryV2<MemEntityV2, Mem> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  MemRepositoryV2._(super.table);

  static MemRepositoryV2? _instance;

  factory MemRepositoryV2([Table? table]) {
    var tmp = _instance;

    if (tmp == null) {
      if (table == null) {
        throw InitializationError();
      }
      _instance = tmp = MemRepositoryV2._(table);
    }

    return tmp;
  }

  static reset() => _instance = null;
}
