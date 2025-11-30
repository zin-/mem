import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart';

part 'mems_dao.g.dart';

@DriftAccessor(tables: [Mems])
class MemsDao extends DatabaseAccessor<AppDatabase> with _$MemsDaoMixin {
  MemsDao(super.database);

  Future<List<Mem>> getMems() async {
    return await select(mems).get();
  }
}
