import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_preposts/mem_prepost_entity.dart';
import 'package:mem/framework/database/accessor.dart';

Future<List<MemPrePostEntity>> shipPrePostsBySourceMemId(int? sourceMemId) => v(
      () async {
        if (sourceMemId == null) return [];
        final db = DriftDatabaseAccessor().driftDatabase;
        final rows = await (db.select(db.memPrePosts)
              ..where((t) => t.sourceMemId.equals(sourceMemId)))
            .get();
        return rows.map(MemPrePostEntity.fromTuple).toList();
      },
      {'sourceMemId': sourceMemId},
    );
