import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart';

part 'mems_dao.g.dart';

@DriftAccessor(tables: [Mems])
class MemsDao extends DatabaseAccessor<AppDatabase> with _$MemsDaoMixin {
  MemsDao(super.database);

  Future<int> insert(MemsCompanion mem) async {
    return await into(mems).insert(mem);
  }

  Future<int> updateOne(MemsCompanion mem) async {
    return await (update(mems)..where((t) => t.id.equals(mem.id.value)))
        .write(mem);
  }

  Future<List<Mem>> getMems() async {
    return await select(mems).get();
  }
}
