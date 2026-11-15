import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_preposts/mem_prepost_entity.dart';
import 'package:mem/framework/database/accessor.dart';

Future<List<MemPrePostEntity>> Function(int? sourceMemId)?
    _shipPrePostsBySourceMemIdOverride;

void bindShipPrePostsBySourceMemId(
  Future<List<MemPrePostEntity>> Function(int? sourceMemId) ship,
) {
  _shipPrePostsBySourceMemIdOverride = ship;
}

Future<List<MemPrePostEntity>> shipPrePostsBySourceMemId(int? sourceMemId) {
  final override = _shipPrePostsBySourceMemIdOverride;
  if (override != null) return override(sourceMemId);
  return _shipPrePostsBySourceMemId(sourceMemId);
}

Future<List<MemPrePostEntity>> _shipPrePostsBySourceMemId(int? sourceMemId) =>
    v(
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
